#include<UserButton.h>
#include "MoteToMote.h"
#include "printf.h"
#include<string.h>

module BaseStationC
{
	uses // genearl intefaces
	{
		interface Boot;
		interface Leds;
	}
	
	uses// button interfaces
	{
		interface Get<button_state_t>;
		interface Notify<button_state_t>;
	}
	
	uses
	{
		interface Packet;
		interface AMPacket;
		interface AMSend;
		interface SplitControl as AMControl;
		interface Receive;
	}

	uses 
	{
		interface Init;
  	interface ParameterInit<uint16_t> as SeedInit;
	}
}

/*-------------------------------------------------------------------------------------*/
/*                                                                                     */
/*-------------------------------------------------------------------------------------*/
implementation
{
	//global variables
	bool radioBusy = FALSE;
	message_t pkt;
	float batteryLvl = 0;

	typedef struct Measurement
	{
		uint16_t Nonce;
		uint16_t Node;
		uint16_t Value;
		
	} Measurement_Msg;
	
	//Heed Variables
	uint8_t heedLevel = 0;
	Measurement_Msg measurements[25];

	// Heed Functions
	void sendMsg(int recipient,char MsgId,uint16_t NodeId,uint8_t Level, uint8_t BatteryLvl, uint32_t Timestamp, uint16_t Measurement);
	void receiveMeasurementMsg(Mote_Msg * pkt);
	void displayLeds(uint8_t _idNodo);

/*-------------------------------------------------------------------------------------*/
/*                                     EVENTS                                          */
/*-------------------------------------------------------------------------------------*/

	event void Boot.booted()
	{
		int i = 0;
		call Notify.enable(); //button
		call AMControl.start();
		
		// BaseStation
		if(TOS_NODE_ID == 1)
		{
			
			heedLevel = 1;
			for(i=0; i<25; i++)
			{
				measurements[i].Node = 0;
				measurements[i].Nonce = 0;
				measurements[i].Value = 0;
			}
		}
		
	}
	
	// white button pressed
	event void Notify.notify(button_state_t val)
	{
		if(val == BUTTON_RELEASED)
		{
			if(heedLevel != 0)
			{
				sendMsg(NULL, 'l', TOS_NODE_ID, heedLevel, batteryLvl, NULL, NULL);
			}
		}
	}
	
	event void AMSend.sendDone(message_t *msg,error_t err)
	{
		if(msg == &pkt)
		{
			radioBusy = FALSE;
		}
	}
	
	event void AMControl.startDone(error_t err)
	{
		if(err != SUCCESS)
		{
			call AMControl.start();
		}
	}
	
	event void AMControl.stopDone(error_t err)
	{		
	}
	
	event message_t * Receive.receive(message_t *msg,void *payload,uint8_t len)
	{
		if(len == sizeof(Mote_Msg))
		{
			Mote_Msg * incomingPkt = (Mote_Msg*) payload;
			char msgId = incomingPkt->MsgId;
		
			if(msgId == 'm')
			{
				receiveMeasurementMsg(incomingPkt);
			}
		}
	
		return msg;
	}

/*-------------------------------------------------------------------------------------*/
/*                                     FUNCTIONS                                        */
/*-------------------------------------------------------------------------------------*/

	void sendMsg(int recipient, char MsgId,uint16_t NodeId,uint8_t Level, uint8_t BatteryLvl, uint32_t Timestamp, uint16_t Measurement)
	{
		int R = AM_BROADCAST_ADDR;

		if(radioBusy == FALSE)
		{
		
			Mote_Msg* msg = call Packet.getPayload(&pkt,sizeof(Mote_Msg));
			
			if(&MsgId != NULL)
			{
				msg->MsgId = MsgId;
			}
			if(&NodeId != NULL)
			{
				msg->NodeId = NodeId;
			}
			if(&Level != NULL)
			{
				msg->Level = Level;
			}
			if(&BatteryLvl != NULL)
			{
				msg -> BatteryLvl = BatteryLvl;
			}
			if(&Timestamp != NULL)
			{
				msg -> Timestamp = Timestamp;
			}
			if(&Measurement != NULL)
			{
				msg -> Measurement = Measurement;
			}
		
			if(recipient != NULL)
			{
				R = recipient;
			}
			if(call AMSend.send(R,&pkt,sizeof(Mote_Msg)) == SUCCESS)
			{
				radioBusy = TRUE;
			}
		}
	}

	void displayLeds(uint8_t _idNodo)
	{
		int l;
		l = _idNodo % 8;

			if(l==0)
			{
				call Leds.led0Off();
				call Leds.led1Off();
				call Leds.led2Off();	
			}
			if(l==1)
			{
				call Leds.led0Off();
				call Leds.led1Off();
				call Leds.led2On();	
			}
			if(l==2)
			{
				call Leds.led0Off();
				call Leds.led1On();
				call Leds.led2Off();	
			}
			if(l==3)
			{
				call Leds.led0Off();
				call Leds.led1On();
				call Leds.led2On();	
			}
			if(l==4)
			{
				call Leds.led0On();
				call Leds.led1Off();
				call Leds.led2Off();	
			}
			if(l==5)
			{
				call Leds.led0On();
				call Leds.led1Off();
				call Leds.led2On();	
			}
			if(l==6)
			{
				call Leds.led0On();
				call Leds.led1On();
				call Leds.led2Off();	
			}
			if(l==7)
			{
				call Leds.led0On();
				call Leds.led1On();
				call Leds.led2On();	
			}	
	}

	void receiveMeasurementMsg(Mote_Msg * pkt) 
	{
		uint8_t id = pkt->NodeId;
		uint32_t t = pkt->Timestamp;
		uint16_t data = pkt->Measurement;

		int i = 0;
		bool flag = TRUE;
		for(i=0; i<25; i++)
		{
			if(measurements[i].Node == id && measurements[i].Nonce == t)
			{
				flag = FALSE;
				break;
			}
		}
		if(flag)
		{
			for(i=23; i>=0; i--)
			{
				measurements[i+1].Node = measurements[i].Node;
				measurements[i+1].Nonce = measurements[i].Nonce;
				measurements[i+1].Value = measurements[i].Value;
			}
			measurements[0].Node = id;
			measurements[0].Nonce = t;
			measurements[0].Value = data;
			
		}
		for(i=0;i<25;i++){printf("%d-",measurements[i].Value);}
		printf("\n");
		printf(" ricevuto da %d\n",id);
		printf(" con timestamp %d", t);
		printf(" con valore %d\n", data);
		printfflush();
	}
}
