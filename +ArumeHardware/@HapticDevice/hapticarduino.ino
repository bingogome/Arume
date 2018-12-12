#include<Wire.h>

const int MPU_addr=0x68; //I2C address of the MPU6050
int32_t AcX,AcY,AcZ;//,Tmp,GyX,GyY,GyZ; not necessary haha

int minVal=265;
int maxVal=402;

double x;
double y;
double z;
double newAngle;
double serinput;
double newreading;
const int RunningAverageCount = 20;
float RunningAverageAngle;
float RunningAverageBuffer[RunningAverageCount];
int NextRunningAverage;

void setup(){
  Wire.begin(); //join I2C bus as master
//  Wire.beginTransmission(MPU_addr);
//  Wire.write(0x6B); //PWR_MGMT_1 register
//  Wire.write(0); //set to 0 and wakes up the MPU-6050
//  Wire.endTransmission(false);
  Serial.begin(9600);

  // For debugging on oscilloscope.
  pinMode(2, OUTPUT);
  pinMode(4, OUTPUT);
  pinMode(6, OUTPUT);
}

void loop()
{
    
  digitalWrite(4, HIGH);
  
    while(Wire.available())
    {
      Wire.read();
    }
  digitalWrite(4, LOW);
    
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x3B); //starting with register 0x3B (ACCEL_XOUT_H)
  //specifying that the data form the 3B register of the slave should be the first one 
  //and the master will receive 6 bytes in total
  //in this case the 6 bytes are continuous
  Wire.endTransmission(false);
//  true will send a stop message after the last byte, releasing the bus after transmission. 
//  false will send a restart, keeping the connection active. 
//  The bus will not be released, which prevents another master device from transmitting between messages. 
//  This allows one master device to send multiple transmissions while in control.
  Wire.requestFrom(MPU_addr,6,true); //request a total of 6 registers- there are 3 variables: AcX/Y/Z
//true will send a stop message after the request, releasing the bus.  
// false will continually send a restart after the request, keeping the connection active. 
// The bus will not be released, which prevents another master device from transmitting between messages. 
// This allows one master device to send multiple transmissions while in control. 
//byte data1 = Wire.read();  // read first byte
//Wire.read();               // read and ignore second byte
//byte data3 = Wire.read();  // read third byte

  //  delay(2);
  digitalWrite(2, HIGH);
//  Serial.println(n,1); 

  // Wait for bytes from I2C for at most 5 milliseconds.
  int endwait = millis() + 5;
  
   while(Wire.available() < 6)
   {
      if (millis() > endwait)
      {
        break;
      }
    }
  int n = Wire.available();
      
  if( n == 6)    // did we receive the number of requested bytes ?
  {
      AcX = Wire.read()<<8; // read MSB first ; 0x3B (ACCEL_XOUT_H) and 0x3C (ACCEL_XOUT_L)
      AcX |=Wire.read(); // then read LSB
      AcY = Wire.read()<<8; //MSB first ; 0x3D (ACCEL_XOUT_H) and 0x3E (ACCEL_YOUT_L)
      AcY |=Wire.read();
      AcZ = Wire.read()<<8; //MSB first; 0x3F (ACCEL_ZOUT_H) and 0x40 (ACCEl_ZOUT_L)
      AcZ |=Wire.read();
      //return a 16 bit integer, where the 8 most significant bits are 0 and the 8 least significant bits contain actual data
      //because of <<8, it becomes xxxxxxxx00000000 in binary
      // the whole expression gives xxxxxxxxyyyyyyyy, where the x comes from 1st wire.read and y come from the 2nd wire.read
        
      int xAng = map(AcX,minVal,maxVal,-90,90);
      int yAng = map(AcY,minVal,maxVal,-90,90);
      int zAng = map(AcZ,minVal,maxVal,-90,90);
    
      x= RAD_TO_DEG * (atan2(-yAng, -zAng)+PI);
      y= RAD_TO_DEG * (atan2(-xAng, -zAng)+PI);
      z= RAD_TO_DEG * (atan2(-yAng, -xAng)+PI);
   
      newAngle = convertAngle(z);
    
      RunningAverageBuffer[NextRunningAverage++] = newAngle; //z is the 'raw angle' value
      if (NextRunningAverage >= RunningAverageCount)
      {
        NextRunningAverage = 0; 
      }
      RunningAverageAngle = 0;
      for(int i=0; i< RunningAverageCount; ++i)
      {
        RunningAverageAngle += RunningAverageBuffer[i];
      }
      RunningAverageAngle /= RunningAverageCount;
  }
  
  //wait for input from matlab, then display number!
  if (Serial.available() )  
  {
    serinput = Serial.read();
    if ((char)serinput == '1' ) //when the character '1' is received (from matlab), print!
    {
      Serial.println(RunningAverageAngle,1); 
    }
    //CLEAR SERIAL READ
    while(Serial.available() )  
    {
      serinput = Serial.read();
    }
  }
  // delay(2);
  digitalWrite(2, LOW);
}

double convertAngle(double z) {
  return 1.2205741373748*pow(10,-6)*pow(z,3) -0.000736988292589112*pow(z,2)-0.892111649933372*z +178.577364289686;
}
