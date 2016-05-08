#include <SPI.h>
#include <PID_v1.h>
#include "Adafruit_MAX31855.h"

#define COILPIN  11
#define DIODEPIN  3

#define MAXDO   8
#define MAXCS   10
#define MAXCLK  9

#define H2MINPIN 0
#define H2MAXPIN 4

//#define VERBOSE

// Initialize the PID vars
double Setpoint, Input, Output;
//double Kp=2, Ki=.01, Kd=.5;
double Kp=3, Ki=.005, Kd=1;
PID myPID(&Input, &Output, &Setpoint, Kp, Ki, Kd, DIRECT);

// Initialize the Thermocouple
Adafruit_MAX31855 thermocouple(MAXCLK, MAXCS, MAXDO);

// Initialize helper variables
bool                fine = true;

unsigned long       newM = 0;
unsigned long       targetM = 0;
unsigned long       tick = 1000;

int                 i = 0;        // Iterator

char                typeByte = 0;

bool                annealing = false;
long                annealStart = 0;
unsigned long       annealTimes[32];
float               annealTemps[32];
unsigned char       annealStep = 0;

inline double interpolate(unsigned long x, unsigned long x1, double y1, unsigned long x2, double y2){
    return (x1 < x2) ? ( ((y2-y1)/((double)(x2-x1)))*((double)(x-x1)) + y1 ) : ( -1 );
}

void setup() {
    Serial.begin(74880);
    pinMode(COILPIN, OUTPUT);
    pinMode(DIODEPIN, OUTPUT);

    for (i = H2MINPIN; i <= H2MAXPIN; i++){
        pinMode(i, INPUT);
    }

    //initialize the variables we're linked to
    Input = 24;
    Setpoint = 0;

    //turn the PID on
    myPID.SetMode(AUTOMATIC);
//  myPID.SetOutputLimits(0,128);
}

void loop() {
    if (Serial.available()){
        typeByte = Serial.read();

        if (typeByte == 's'){
            annealing = false;
            Setpoint = Serial.parseFloat();
#ifdef VERBOSE
            Serial.print("Setpoint set to ");
            Serial.print(Setpoint);
            Serial.println(" deg C.");
#endif
        }
        else if (typeByte == 'a'){
            annealStart = millis();
            annealStep = 0;

            i = 0;
            while (i < 32){                         // Reset list
                annealTimes[i] = 0;
                annealTemps[i] = -1;
                i++;
            }
#ifdef VERBOSE
            Serial.print("Cleared Anneal List");
#endif
            i = 0;
            while (Serial.available() && i < 31){   // Fill list with data
                annealTimes[i] = (unsigned long)(Serial.parseFloat()*60*60*1000); // Convert to milliseconds
                annealTemps[i] = Serial.parseFloat();
#ifdef VERBOSE
                Serial.print("Time: "); Serial.print(  annealTimes[i]);
                Serial.print("Temp: "); Serial.println(annealTemps[i]);
#endif
                i++;
            }

#ifdef VERBOSE
            Serial.print("Filled Anneal List");
            Serial.print("Len:");
            Serial.println(i);
#endif
            // if (Serial.available()){ errorcheck(); }

            annealing = true;
        }
    }

    newM = millis();

    if (annealing){
        if (newM - annealStart > annealTimes[annealStep+1]){
            annealStep++;
        }

        Setpoint = interpolate(newM - annealStart, annealTimes[annealStep], annealTemps[annealStep], annealTimes[annealStep+1], annealTemps[annealStep+1]);

        if (annealTemps[annealStep+1] == -1){
            annealing = false;
            Setpoint = 0;
        }
    }

    double c = thermocouple.readCelsius();
    if (isnan(c)) {
#ifdef VERBOSE
        Serial.println("Something wrong with thermocouple!"); // Turning furnace off momentarily...
        Serial.print("Error Code: ");
        Serial.println(thermocouple.readError());
#endif
//        analogWrite(COILPIN, 0);      // Errors happen a lot at high temperatures. Not sure why...
//        analogWrite(DIODEPIN, 0);
    } else {
#ifdef VERBOSE
        //    Serial.print("newM: ");
        //    Serial.print(newM);
        //    Serial.print(", targetM: ");
        //    Serial.print(targetM);
        //    Serial.print(", targetM - tick:");
        //    Serial.println(targetM - tick);
#endif
        if (targetM < newM && targetM + tick < newM + tick){ // Second check neccessary for integer overflow
            targetM += tick;
#ifdef VERBOSE
            Serial.print(" C = ");
#endif

            Serial.print(c);            // Temperature
            Serial.print(" ");
            Serial.print(Setpoint);     // Setpoint
#ifdef VERBOSE
        Serial.print(",  Duty Cycle =");
#endif
        Serial.print(" ");
        Serial.print(Output/2.55);
#ifdef VERBOSE
        Serial.print(" %");
#endif
            for (i = H2MINPIN; i <= H2MAXPIN; i++){
#ifdef VERBOSE
                Serial.print(", H2 ");
                Serial.print(i);
                Serial.print(" =");
#endif
                Serial.print(" ");
                Serial.print((float)analogRead(i));    // H2 Level on sensor i
                // Serial.print(" ");
            }

            Serial.print("\n");
        }

        Input = c;

        if (fine){
            myPID.Compute();
            analogWrite(COILPIN, Output);
            analogWrite(DIODEPIN, Output);
        }
    }
}
