#include <msp430.h>
// Oliver Gough, EELE 371, 3/16/24

int main(void)
{
	WDTCTL = WDTPW | WDTHOLD;	// stop watchdog timer
	int count = 0;              //set up count
	int sw1;
	int sw2;

//setting up led 1
	P1DIR   |=  BIT0;
	P1OUT   &=  ~BIT0;

//setting up led2
	P6DIR   |=  BIT6;
	P6OUT   &=  ~BIT6;

//setting up switch 1
	P4DIR   &=  ~BIT1;
	P4REN   |=  BIT1;
	P4OUT   |=  BIT1;
	P4IES   |=  BIT1; //irq sense h-l comment out for demo 1

//setting up switch 2
	P2DIR   &=  ~BIT3;
	P2REN   |=  BIT3;
	P2OUT   |=  BIT3;
    P2IES   |=  BIT3; //irq sense h-l comment out for demo 1

 //set up irq
    P4IFG   &=  ~BIT1;
    P4IE    |=  BIT1;
    P2IFG   &=  ~BIT3;
    P2IE    |=  BIT3;
    __enable_interrupt();

	PM5CTL0 &= ~LOCKLPM5;

//while loop
	while(1){

	    //reading ports and clearing bits
	    sw1 = P4IN;
	    sw2 = P2IN;
	    sw1 &= BIT1;
        sw2 &= BIT3;

//increment if s1 is pressed
	   if(sw1 == 0){
	       count ++;
	  //setting threshold of 3
	           if(count > 3){
	              count = 3;
	           }
	       displayCount(count);
	       delayLoop();
	   }
//decrement if s2 is pressed
	    if(sw2 == 0){
	           count = count -2;
	    //setting threshold of 0
	           if(count < 0){
	                  count = 0;
	              }
	           displayCount(count);
	           delayLoop();
	        }
	}
	return 0;
}

//runs ffffx2 times to delay program
void delayLoop(void){
    int i, j;
    for(i = 0; i<0xFFFF; i++){
        for(j = 0; j< 0x2; j++){
        }
    }
    return;
}

//displays the count on the leds in binary using switch statment
void displayCount(int count){
     switch(count){
         case   0:
             P1OUT  &=  ~BIT0;
             P6OUT  &=  ~BIT6;
             break;
         case   1:
             P1OUT  &=  ~BIT0;
             P6OUT  |=  BIT6;
             break;
         case   2:
             P1OUT  |=  BIT0;
             P6OUT  &=  ~BIT6;
             break;
         case   3:
             P1OUT  |=  BIT0;
             P6OUT  |=  BIT6;
             break;
     }
}

#pragma vector = PORT4_VECTOR
__interrupt void ISR_Port4_S1(void){
    count ++;
    P4IFG &= ~BIT1;
}
#pragma vector = PORT2_VECTOR
__interrupt void ISR_Port2_S2(void){
    count = count -2;
    P2IFG &= ~BIT3;
}
