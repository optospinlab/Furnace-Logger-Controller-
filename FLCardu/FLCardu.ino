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

#define MAXTEMP  1300

//#define VERBOSE

// Initialize the PID vars.
double Setpoint, Input, Output;
double Kp=3, Ki=.005, Kd=1;
PID myPID(&Input, &Output, &Setpoint, Kp, Ki, Kd, DIRECT);

// Initialize the thermocouple.
Adafruit_MAX31855 thermocouple(MAXCLK, MAXCS, MAXDO);

// Initialize helper variables.
unsigned long       newM = 0;           // Stores the current time      (ms since start),
unsigned long       targetM = 0;        // Stores the next update time  (ms since start),
unsigned long       tick = 1000;        // Time between updates         (ms).

int                 i = 0;              // Iterator.

char                typeByte = 0;       // For storing the type of message that has been sent from MATLAB.

unsigned char       thermFails = 0;     // Counts the number of thermocouple failures.

// Initialize annealing vars.
bool                annealing = false;  // Is there an anneal?
long                annealStart = 0;    // Holds the start time of the anneal   (ms since start).
unsigned long       annealTimes[32];    // Holds the times (ms since anneal start)...
float               annealTemps[32];    // ...and holds the temps (C) for a list of [time, temp] points that comprise an anneal.
unsigned char       annealStep = 0;     // Hold the index of the [time, temp] point that has been most recently passed.

// Helper function. Self-explanatory. Returns -1 if x1 >= x2.
inline double interpolate(unsigned long x, unsigned long x1, double y1, unsigned long x2, double y2){
    return (x1 < x2) ? ( ((y2-y1)/((double)(x2-x1)))*((double)(x-x1)) + y1 ) : ( -1 );
}

void setup() {
    Serial.begin(74880);        // Initialize serial (make sure the Baud rates are the same as MATLAB).
    
    pinMode(COILPIN, OUTPUT);   // Initialize the coil and diode pins as outputs.
    pinMode(DIODEPIN, OUTPUT);

    for (i = H2MINPIN; i <= H2MAXPIN; i++){
        pinMode(i, INPUT);      // Initialize all the hydrogen sensors.
    }

    // Initialize the variables the PID is linked to, along with the PID.
    Input = 24;
    Setpoint = 0;
    myPID.SetMode(AUTOMATIC);
}

void loop() {
    if (Serial.available()){        // If MATLAB has something to say...
        typeByte = Serial.read();   // ...read it.

        if (typeByte == 's'){                       // If that something is a single setpoint...
            annealing = false;                      // ...stop any anneals...
            Setpoint = Serial.parseFloat();         // ...and set the Setpoint to the next float in the serial buffer.
#ifdef VERBOSE
            Serial.print("Setpoint set to ");
            Serial.print(Setpoint);
            Serial.println(" deg C.");
#endif
        }
        else if (typeByte == 'a'){                  // Otherwise, if that something is an anneal...
            annealStart = millis();                 // ...record the time that the anneal started...
            annealStep = 0;                         // ...and set the current step to zero.

            i = 0;
            while (i < 32){                         // Then, reset the list of [time, temp] points to [0, -1] points
                annealTimes[i] = 0;
                annealTemps[i] = -1;
                i++;
            }
#ifdef VERBOSE
            Serial.print("Cleared Anneal List");
#endif
            i = 0;
            while (Serial.available() && i < 31){                                   // Fill the list (except for the last point) with data
                annealTimes[i] = (unsigned long)(Serial.parseFloat()*60*60*1000);   // Convert the times (hours) to ms
                annealTemps[i] = Serial.parseFloat();                               // Do not convert the temperatures
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
            
            annealing = true;                       // And start the anneal
            
            if (Serial.available()){                // However, if there still is data, stop the anneal (this will not warn the MATLAB program)
                annealing = false;
#ifdef VERBOSE
                Serial.print("Warning: Annealing list too long...");
#endif
            }
        }
    }
    
    newM = millis();    // Figure out the current time.

    if (annealing){                                             // If we are currently annealing...
        if (newM - annealStart > annealTimes[annealStep+1]){    // ...check to see if we need to move to the next [time, temp] pair...
            annealStep++;                                       // ...and incriment.
        }
        
        // Set the setpoint to the linear interpolation of our current step and the next step.
        Setpoint = interpolate(newM - annealStart, annealTimes[annealStep], annealTemps[annealStep], annealTimes[annealStep+1], annealTemps[annealStep+1]);
        
        if (Setpoint < 0){                                      // If there was an erro with the thermocouple...
            Setpoint = 0;
#ifdef VERBOSE
            Serial.println("Error with interpolation!");
#endif
        }
        
        if (annealTemps[annealStep+1] == -1){                   // If the next step is -1 (finished the list), then stop annealing.
            annealing = false;
            Setpoint = 0;
#ifdef VERBOSE
            Serial.println("Anneal finished!");
#endif
        }
    }

    Input = thermocouple.readCelsius();     // Read the temperature.
    if (isnan(Input)) {
        thermFails++;                       // The thermocouple is failing...
#ifdef VERBOSE
        Serial.println("Something wrong with thermocouple!");
        Serial.print("Error Code: ");
        Serial.println(thermocouple.readError());
#endif
        if (thermFails > 31){
            analogWrite(COILPIN, 0);        // If there are 32 fails in a row, turn the furnace off...
            analogWrite(DIODEPIN, 0);
        }
    } else {
        thermFails = 0;                     // The thermocouple is not failing...
        
#ifdef VERBOSE
//        // Debugging tools
//        Serial.print("newM: ");
//        Serial.print(newM);
//        Serial.print(", targetM: ");
//        Serial.print(targetM);
//        Serial.print(", targetM - tick:");
//        Serial.println(targetM - tick);
#endif
        if (targetM < newM && targetM + tick < newM + tick){    // If it's time to send data to MATLAB... (second check neccessary for long overflow)
            targetM += tick;
            
#ifdef VERBOSE
            Serial.print(" C = ");
#endif

            Serial.print(Input);                        // Send the temperature,
            
#ifdef VERBOSE
            Serial.print(" Setpoint =");
#endif
            
            Serial.print(" ");
            Serial.print(Setpoint);                     // Send the setpoint,
            
#ifdef VERBOSE
            Serial.print(",  Duty Cycle =");
#endif
            
            Serial.print(" ");
            Serial.print(Output/2.55);                  // Send the duty cycle,
            
#ifdef VERBOSE
            Serial.print(" %");
#endif
            
            for (i = H2MINPIN; i <= H2MAXPIN; i++){
#ifdef VERBOSE
                Serial.print(", H2 #");
                Serial.print(i);
                Serial.print(" =");
#endif
                
                Serial.print(" ");
                Serial.print((float)analogRead(i));    // Send the H2 Level on sensor i (out of 1024).
            }

            Serial.print("\n");
        }
        
        if (Input < MAXTEMP) {              // If the temperature is under the hardcoded limit...
            myPID.Compute();                // ...calculate the current duty cycle...
            analogWrite(COILPIN, Output);   // ...and output the result.
            analogWrite(DIODEPIN, Output);
        } else {                            // Otherwise...
            analogWrite(COILPIN, 0);        // ...turn the furnace off.
            analogWrite(DIODEPIN, 0);
        }
    }
}
