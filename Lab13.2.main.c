#include <msp430.h> 
//Oliver Gough, EELE 371, 3/17/24
int timer_2 = 250;

int main(void)
{
	WDTCTL = WDTPW | WDTHOLD;	// stop watchdog timer
	
	//setting up led 1
	    P1DIR   |=  BIT0;
	    P1OUT   &=  ~BIT0;

    //setting up switch 1
        P4DIR   &=  ~BIT1;
        P4REN   |=  BIT1;
        P4OUT   |=  BIT1;
        P4IES   |=  BIT1; //irq sense h-l comment out for demo 1

    //set up timer B0
        TB0CTL  |=  TBCLR;
        TB0CTL  |=  TBSSEL__SMCLK; //fix this to one mega hz
        TB0CTL  |=  MC__UP;
        TB0CCR0 =  1050;      //nums
        TB0CCR1 =  250;      //nums

    //set up timer compare
        TB0CCTL0 |= CCIE;
        TB0CCTL0 &= ~CCIFG;
        TB0CCTL1 |= CCIE;
        TB0CCTL1 &= ~CCIFG;

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

        while(1){

        }

	return 0;
}
//increase pmw by 25 to a limit of 500
int pmw_increase(timer_2){
    timer_2 = timer_2 + 25;
    if(timer_2 > 500){
        timer_2 = 500;
    }
    return timer_2;
}
//decrease pmw by 25 at a limit of 25
int pmw_decrease(timer_2){
    timer_2 = timer_2 - 25;
    if(timer_2 < 25){
        timer_2 = 25;
    }
    return timer_2;
}

//sw1 interupt
#pragma vector = PORT4_VECTOR
__interrupt void ISR_Port4_S1(void){
    timer_2 = pmw_increase(timer_2);
    TB0CCR1 = timer_2;
    P4IFG &= ~BIT1;
}
//sw2 interput
#pragma vector = PORT2_VECTOR
__interrupt void ISR_Port2_S2(void){
    timer_2 = pmw_decrease(timer_2);
    TB0CCR1 = timer_2;
    P2IFG &= ~BIT3;
}
//
#pragma vector = TIMER0_B0_VECTOR
__interrupt void ISR_TB0_CCR0(void){
    P1OUT   |=  BIT0;
    TB0CCTL0 &= ~CCIFG;
}
//
#pragma vector = TIMER0_B1_VECTOR
__interrupt void ISR_TB0_CCR1(void){
    P1OUT   &=  ~BIT0;
    TB0CCTL1 &= ~CCIFG;
}
