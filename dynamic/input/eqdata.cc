#include <iostream>
#include <fstream>
#include <string>
#include <stdio.h>

#include <earthq.h>

using namespace std;
float parseCsv(ifstream& file);

int main(int argc, char* argv[])
{
  string eq1 = "type2-II-1.dat";
  string eq2 = "type2-II-2.dat";
  string eq3 = "type2-II-3.dat";

  int datanum = 4000;
  cout << "datanum = " << datanum << endl;

  ifstream IN1(eq1.c_str());
  ifstream IN2(eq2.c_str());
  ifstream IN3(eq3.c_str());

  double deltaT = 0.01;  

  // original accel. data at table
  float d; // dummy
  double *time = new double [datanum];

  double **eData = new double* [3];
  for(int i=0; i<3; i++) {
    eData[i] = new double [datanum];
  }

  for(int i=0; i<datanum; i++) {
    time[i] = deltaT*(double)i;
    IN1 >> d >> eData[NS][i];
    IN2 >> d >> eData[EW][i];
    IN3 >> d >> eData[UD][i];
  }

  Earthquake edata;
  edata.setWaveData(datanum, deltaT, eData, time);

  ofstream OUT("out.dat");
  ofstream OUT1("eq1.dat");
  ofstream OUT2("eq2.dat");
  ofstream OUT3("eq3.dat");
  for(int i=0; i<datanum; i++) {
    OUT << time[i] << ' ' << edata.getData(NS, i)
	<< ' ' << edata.getData(EW, i) << ' ' << edata.getData(UD, i) << endl;
    OUT1 << edata.getData(NS, i) << endl;
    OUT2 << edata.getData(EW, i) << endl;
    OUT3 << edata.getData(UD, i) << endl;
  }
  //  accR.bandPassFilter("accband.dat", 0.3, 40.);
  //  Earthquake accB;
  //  accB.readWaveData2("accband.dat");

  //  accT.calcSmoothFourierAmp("fourierT.dat", 50);
  //  accB.calcSmoothFourierAmp("fourierR.dat", 50);
//  accR.calcSmoothFourierAmp("fourierR.dat", 50);

  edata.calcResponseSpectra2("resp.dat", 0.05, 0.1, 10.0);

  for(int i=0; i<datanum; i++) {
    eData[NS][i] *= 0.16;
    eData[EW][i] *= 0.165;
    eData[UD][i] *= 0.13;
  }
  Earthquake edata2;
  edata2.setWaveData(datanum, deltaT, eData, time);
  edata2.calcResponseSpectra2("resp2.dat", 0.05, 0.1, 10.0);
  //  accB.calcResponseSpectra2("respR.dat", 0.05);
//  accR.calcResponseSpectra2("respR.dat", 0.05);

  return 0;
}
