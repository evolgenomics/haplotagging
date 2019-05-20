/*                                          
 * variant_file.cpp
 *
 *  Created on: Jan 28, 2019
 *      Authors: Andreea Dreau, https://github.com/adreau
 *               Frank Chan, https://github.com/evolgenomics
 */

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <map>
#include <utility>
#include <vector>
#include <gzstream.h>

using namespace std;

string barcode_A="BC_A.txt";
string barcode_B="BC_B.txt";
string barcode_C="BC_C.txt";
string barcode_D="BC_D.txt";

map<string,string> bc_A;
map<string,string> bc_B;
map<string,string> bc_C;
map<string,string> bc_D;

typedef pair<unsigned int, unsigned int> pair_int;


unsigned int edit_distance(const std::string& s1, const std::string& s2)
{
	const size_t len1 = s1.size(), len2 = s2.size();
	vector<std::vector<unsigned int>> d(len1 + 1, vector<unsigned int>(len2 + 1));

	d[0][0] = 0;
	for(unsigned int i = 1; i <= len1; ++i) d[i][0] = i;
	for(unsigned int i = 1; i <= len2; ++i) d[0][i] = i;

	for(unsigned int i = 1; i <= len1; ++i)
		for(unsigned int j = 1; j <= len2; ++j)
                      // note that std::min({arg1, arg2, arg3}) works only in C++11,
                      // for C++98 use std::min(std::min(arg1, arg2), arg3)
                      d[i][j] = min(min( d[i - 1][j] + 1, d[i][j - 1] + 1), d[i - 1][j - 1] + (s1[i - 1] == s2[j - 1] ? 0 : 1) );
	return d[len1][len2];
}

string min_edit_distance(const std::string& s1, map<string,string> bc, string code_letter){

  int min=10000;
  string code_min_dist;
  string code_str;
  int ed,occ=0;
  map<string,string>::iterator it;
  for(it=bc.begin();it!=bc.end();it++){
    ed=edit_distance(s1,it->first);
    //cout<<it->first<<":"<<ed<<endl;
    if(min>ed){
      min=ed;
      code_min_dist=it->second;
      code_str=it->first;
      occ=1;
    }else
    if(min==ed){
      occ++;
    }
  }

	if(occ>1)
		code_min_dist=code_letter+"00";

  //cout<<"Occurences: "<<occ<<endl;
  //cout<<"Min dist: "<<min<<endl;
  //cout<<"Code:"<<s1<<" Corrected to:" <<code_str<<endl;
  return code_min_dist;

}
void load_barcodes(map<string,string> &bc_list,string file){

    ifstream barcode_file(file.c_str());
    string line;
    while(getline(barcode_file, line)){
      bc_list.insert( std::pair<string,string> (line.substr(4),line.substr(0,3)) );
    }


}

void load_all_barcodes(){

  load_barcodes(bc_A,barcode_A);
  load_barcodes(bc_B,barcode_B);
  load_barcodes(bc_C,barcode_C);
  load_barcodes(bc_D,barcode_D);

}



void getCode(igzstream &I1, string &codeA, string &codeC,
						string& RX1, string& QX1, string& read_type1,
						int code_total_length, string code_letter1, string code_letter2,
						map<string,string> bc1,map<string,string> bc2){

	read_type1="correct";

  string line;
	string codeA_inFile,codeC_inFile;
  map<string,string>::iterator a;
  map<string,string>::iterator c;
  for(int i=0;i<2;i++)
    getline(I1, line);

	RX1=line;

  if(line.length()<code_total_length){
    codeA=code_letter1+"00";
    codeC=code_letter2+"00";
  }else{
		codeA_inFile=line.substr(7);
    a=bc1.find(codeA_inFile);
    if(a==bc1.end()){
      codeA=min_edit_distance(codeA_inFile,bc1,code_letter1);
			read_type1="corrected";
    }else
      codeA=a->second;

		codeC_inFile=line.substr(0,6);
    c=bc2.find(codeC_inFile);
    if(c==bc2.end()){
      codeC=min_edit_distance(codeC_inFile,bc2,code_letter2);
			read_type1="corrected";
    }else
      codeC=c->second;

  }

	if(codeA.compare(code_letter1+"00")==0 || codeC.compare(code_letter2+"00")==0){
		read_type1="unclear";
	}

  getline(I1, line);
	getline(I1, line);
	QX1=line;
}


int main (int argc, char* argv[])
{

  load_all_barcodes();
  cout << "loaded barcodes: " << bc_A.size() << " A, " << bc_B.size() << " B, "
                              << bc_C.size() << " C, " << bc_D.size() << " D "<<endl;


  string path_to_reads=argv[1];
  string path_output=argv[2];

  string R1_file=path_to_reads+"R1_001.fastq.gz";
  string R2_file=path_to_reads+"R2_001.fastq.gz";
  string I1_file=path_to_reads+"I1_001.fastq.gz";
  string I2_file=path_to_reads+"I2_001.fastq.gz";

  string R1_outfile=path_output+"_R1_001.fastq.gz";
  string R2_outfile=path_output+"_R2_001.fastq.gz";

	string clearBC_logfile=path_output+"_clearBC.log";
	string unclearBC_logfile=path_output+"_unclearBC.log";

  igzstream R1(R1_file.c_str());
  igzstream R2(R2_file.c_str());
  igzstream I1(I1_file.c_str());
  igzstream I2(I2_file.c_str());

	ogzstream R1_out(R1_outfile.c_str());
	ogzstream R2_out(R2_outfile.c_str());


	ofstream clearBC_log(clearBC_logfile.c_str());
	ofstream unclearBC_log(unclearBC_logfile.c_str());


  string codeA,codeB,codeC,codeD;
	string RX1, RX2, QX1, QX2;
	//read type: correct, corrected, unclear
	string read_type1, read_type2;

	string R1_out_name,R2_out_name;

	map<string,pair_int> clear_read_map;
	map<string,pair_int>::iterator it_clear;
	map<string,int> unclear_read_map;
	map<string,int>::iterator it_unclear;

  string line;
  string name;
	string code;
  int posName;
	
	while (getline(R1, line))
	{

    getCode(I1,codeA,codeC,RX1,QX1,read_type1,13, "A", "C", bc_A, bc_C);
    getCode(I2,codeB,codeD,RX2,QX2,read_type2,13, "B", "D", bc_B, bc_D);

    posName=line.find(" ");
  	name=line.substr(0,posName+1);

		//append BX tag
    name=name.append("BX:Z:");
    name=name.append(codeA);
    name=name.append(codeC);
    name=name.append(codeB);
    name=name.append(codeD);

		code=codeA+codeC+codeB+codeD;

		//append RX tag
		name=name.append("\tRX:Z:");
		name=name.append(RX1);
		name=name.append("+");
		name=name.append(RX2);


		//append QX tag
		name=name.append("\tQX:Z:");
		name=name.append(QX1);
		name=name.append("+");
		name=name.append(QX2);

    R1_out<<name<<endl;
    R2_out<<name<<endl;

    for(int i=0;i<3;i++){
      getline(R1, line);
      R1_out<<line<<endl;
    }
    getline(R2, line);
    for(int i=0;i<3;i++){
      getline(R2, line);
      R2_out<<line<<endl;
    }

		//sort reads clear vs unclear
		if(read_type1.compare("unclear")==0 || read_type2.compare("unclear")==0){

			it_unclear=unclear_read_map.find(code);
			if(it_unclear!=unclear_read_map.end())
				it_unclear->second++;
			else
				unclear_read_map.insert( pair<string,int>(code,1));

    }else{

			it_clear=clear_read_map.find(code);
			if(read_type1.compare("corrected")==0 || read_type2.compare("corrected")==0){

				if(it_clear!=clear_read_map.end())
					it_clear->second.second++;
				else
					clear_read_map.insert( make_pair(code, make_pair(0,1)) );

	    } else{

				if(it_clear!=clear_read_map.end())
					it_clear->second.first++;
				else
					clear_read_map.insert( make_pair(code, make_pair(1,0)) );

			}
		}

  }

	R1_out.close();
  R2_out.close();


	clearBC_log << "Barcode \t Correct reads \t Corrected reads" <<endl;
	for ( map<string,pair_int>::iterator it=clear_read_map.begin(); it!=clear_read_map.end(); ++it)
		clearBC_log << it->first << "\t" << it->second.first << "\t" << it->second.second << endl;
	clearBC_log.close();


	unclearBC_log << "Barcode \t Reads" <<endl;
	for ( map<string,int>::iterator it=unclear_read_map.begin(); it!=unclear_read_map.end(); ++it)
		unclearBC_log << it->first << "\t" << it->second << endl;
	unclearBC_log.close();

  return 0;
}
