#include <msp430.h> 
//Oliver Gough, EELE 371, 3/31/24

char full_name[] = "Oliver Gough ";
char first_name[] = "Oliver ";
unsigned int position;
int i;
int sw_flag = 0; //1 == sw1 pressed 2 == sw 2 pressed

int main(void)
{
    WDTCTL = WDTPW | WDTHOLD;   // stop watchdog timer

    //-- 1. Put eUSCI_A1 in SW reset
    UCA1CTLW0 |= UCSWRST;

    //-- 2. Configure eUSCI_A1
    UCA1CTLW0 |= UCSSEL__SMCLK; //use smclk as brclk
    UCA1BRW = 8;        //low freq baud rate baud 9600 CHANGE BY LAB TIME
    UCA1MCTLW |= 0xD600; //baud rate setting

    //-- 3. configure ports
    P1DIR |= BIT0;  //set leds as out
    P6DIR |= BIT6;
    P1OUT |= BIT0;                    //led 1 on
    P6OUT &= ~BIT6;                   //led 2 off

    P4DIR &= ~BIT1; //intertupt for s 1
    P4REN |= BIT1;
    P4OUT |= BIT1;
    P4IES |= BIT1;

    P2DIR &= ~BIT3; //intertupt for s 2
    P2REN |= BIT3;
    P2OUT |= BIT3;
    P2IES |= BIT3;

    P4SEL1 &= ~BIT3; //uart ports
    P4SEL0 |= BIT3;

    PM5CTL0 &= ~LOCKLPM5;

    //-- 4. take out of software reset
    UCA1CTLW0 &= ~UCSWRST;

    //-- 5. Enable IRQs
    P4IFG &= ~BIT1;
    P4IE |= BIT1;

    P2IFG &= ~BIT3;
    P2IE |= BIT3;
    __enable_interrupt();

    while (1){
        /*
        UCA1TXBUF = 'E'; ;//put in E to the buffer
        for(i=0; i< 10000; i++){ //delay
        }
      */
    }
    return 0;
}

//--------------DEMO 2 ISR START------------------------------------
#pragma vector = PORT4_VECTOR //isr for switch 4 ie put 0 into positon to print first name
__interrupt void ISR_Port4_S1(void){
    position = 0;
    UCA1IE |= UCTXCPTIE;
    UCA1IFG &= ~UCTXCPTIFG;
    UCA1TXBUF = first_name[position];
    sw_flag = 1;
    P4IFG &= ~BIT1;
}
#pragma vector = PORT2_VECTOR//isr for switch 2, put 7 into postion and print last name
__interrupt void ISR_Port2_S2(void){
    position = 7;
    UCA1IE |= UCTXCPTIE;
    UCA1IFG &= ~UCTXCPTIFG;
    UCA1TXBUF = full_name[position];
    sw_flag = 2;
    P2IFG &= ~BIT3;
}
#pragma vector = EUSCI_A1_VECTOR
__interrupt void ISR_EUSCI_A1(void){
    if(sw_flag == 1){
        if(position == sizeof(first_name)-1){
            P1OUT |= BIT0;                    //led 1 on
            P6OUT &= ~BIT6;                   //led 2 off
            UCA1IE &= ~UCTXCPTIE;
        } else {
            position++;
            UCA1TXBUF = first_name[position];
        }
    } else {
        if(position == sizeof(full_name)-1){
            P1OUT &= ~BIT0;                    //led 1 off
            P6OUT |= BIT6;                   //led 2 on
            UCA1IE &= ~UCTXCPTIE;
        } else {
            position++;
            UCA1TXBUF = full_name[position];
                }
    }

    UCA1IFG &= ~UCTXCPTIFG;
}
//--------------DEMO 2 ISR END------------------------------------


