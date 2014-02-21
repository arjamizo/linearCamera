#include "taskFlyport.h"

void FlyportTask2()
{
 
const int maxBright = 100;    //here we set max % of brightness
const int minBright = 0;    //and here the min %
float bright = (float)maxBright;

int static initialized=0;
if(!initialized) {
    initialized=1;
    PWMInit(1,50,maxBright);
    PWMOn(p19, 1);//Assign pin 9 as PWM1 and turns it on   
}
//while(1)
{
    for (bright = maxBright; bright > minBright; bright--)
    {
        PWMDuty(bright, 1);
        vTaskDelay(1);    //used to slow down the effect
    }
    for (bright = minBright; bright < maxBright; bright ++)
    {
        PWMDuty(bright, 1);
        vTaskDelay(1);    //used to slow down the effect
    }
    UARTWrite(1,"changed");
}
}



/****** Capture Images:*******
 * 
 * Start Clock  
 * Set frequency
 * loop 128 times 
 * ready
 */

#define TAOS_SI_HIGH IOPut(p6,on)
#define TAOS_SI_LOW IOPut(p6,off)
#define TAOS_CLK_HIGH IOPut(p4,on)
#define TAOS_CLK_LOW IOPut(p4,off)
#define TAOS_EXPOSURE_DELAY {if(0)UARTWrite(1, "waiting start...\r\n");int j; for(j=0; j<30; j++);if(0)UARTWrite(1, "waiting end.\r\n");} //vTaskDelay(1)
#define GET_CAMERA_ANALOG_OUT ADCVal(4)

void ImageCapture(int *data)
{
    static int initialized=0;
    if(!initialized) {
        initialized=1;
        IOInit(p4,out);
        IOInit(p6,out);
    }
    unsigned char i;
    
    TAOS_SI_HIGH;
    TAOS_EXPOSURE_DELAY;
    TAOS_CLK_HIGH;
    TAOS_EXPOSURE_DELAY;
    TAOS_SI_LOW;
    TAOS_EXPOSURE_DELAY;
    data[0] = GET_CAMERA_ANALOG_OUT;// inputs data from camera (first pixel)
    TAOS_CLK_LOW;
    
    for(i=1;i<128;i++)
    {
        TAOS_EXPOSURE_DELAY;
        // TAOS_EXPOSURE_DELAY;
        TAOS_CLK_HIGH;
        TAOS_EXPOSURE_DELAY;
        // TAOS_EXPOSURE_DELAY;
        data[i] = GET_CAMERA_ANALOG_OUT; // inputs data from camera (one pixel each time through loop)
        TAOS_CLK_LOW;
    }
    
    TAOS_EXPOSURE_DELAY;
    // TAOS_EXPOSURE_DELAY;
    TAOS_CLK_HIGH;
    TAOS_EXPOSURE_DELAY;
    // TAOS_EXPOSURE_DELAY;
    TAOS_CLK_LOW;    
}

char t[1000];
void FlyportTask()
{
	// Flyport connects to default network
	//WFConnect(WF_DEFAULT);
	//while(WFGetStat() != CONNECTED);
	vTaskDelay(25);
	UARTWrite(1,"Flyport initialized...hello world!\r\n");
//p18 - AI4 acts as camera reader //http://wiki.openpicus.com/index.php/USB_NEST
//p4     JP5 - OUT1/PWM     Digital output acts as CLK
//p6     JP5 - OUT2/PWM     Digital output acts as SI (signal input)
    int CBT=128;
    int row[128];
    //int i;for(i=0;i<CBT;i++)row[i]=0;
    //if (0)
	while(1)
	{
        ImageCapture(row);
        int prog=0;
        int i;
        for (i = 0; i < CBT; ++i) 
        {
            int this=sprintf(t+prog,"%d ", row[i]);
            prog+=this;
        }
        prog+=sprintf(t+prog, "\r\n");
        UARTWrite(1, t);
        // vTaskDelay(100);
        //FlyportTask2();
	}
    while(1);
}
