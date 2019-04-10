/*#define NEW_PRINTF_SEMANTICS
#include "printf.h"*/
configuration BaseStationAppC
{
}
implementation
{
	components BaseStationC as App;
	components MainC;
	components LedsC;

	App.Boot -> MainC;
	App.Leds -> LedsC;
	
  components PrintfC;
  components SerialStartC; // importantissimo se no non funziona il printf

	components UserButtonC;
	App.Get -> UserButtonC;
	App.Notify -> UserButtonC;
	
	//radio comunication
	components ActiveMessageC;
	components new AMSenderC(AM_RADIO);
	components new AMReceiverC(AM_RADIO);
	
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.Receive -> AMReceiverC;
	
}
