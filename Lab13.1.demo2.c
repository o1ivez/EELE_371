#include <msp430.h>
// Oliver Gough, EELE 371, 3/16/24

int up_1 = 0;
int down_2 = 0;

int main(void){
    WDTCTL = WDTPW | WDTHOLD;   // stop watchdog timer
    int count = 0;              //set up count


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
        //up 1
        if(up_1 != 0){
        count ++;
        //setting threshold of 3
                 if(count > 3){
                    count = 3;
                 }
        up_1 = 0;
        displayCount(count);
    }
    if(down_2 != 0){
        count = count -2;
        //setting threshold of 0
        if(count < 0){
            count = 0;
         }
        down_2 = 0;
        displayCount(count);
    }
    }
    return 0;
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
    up_1 = 1;
    P4IFG &= ~BIT1;
}
#pragma vector = PORT2_VECTOR
__interrupt void ISR_Port2_S2(void){
    down_2 = 1;
    P2IFG &= ~BIT3;
}
