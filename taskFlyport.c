#include "taskFlyport.h"

void FlyportTask()
{
 
const int maxBright = 100;    //here we set max % of brightness
const int minBright = 0;    //and here the min %
float bright = (float)maxBright;
 
PWMInit(1,50,maxBright);
    PWMOn(p19, 1);//Assign pin 9 as PWM1 and turns it on
 
while(1)
{
    for (bright = maxBright; bright > minBright; bright--)
    {
        PWMDuty(bright, 1);
        vTaskDelay(3);    //used to slow down the effect
    }
    for (bright = minBright; bright < maxBright; bright ++)
    {
        PWMDuty(bright, 1);
        vTaskDelay(3);    //used to slow down the effect
    }
    UARTWrite(1,"changed");
}
}

void FlyportTask2()
{
	// Flyport connects to default network
	WFConnect(WF_DEFAULT);
	while(WFGetStat() != CONNECTED);
	vTaskDelay(25);
	UARTWrite(1,"Flyport Wi-fi connected...hello world!\r\n");

	while(1)
	{
		//	Main user's firmware loop
	}
}
