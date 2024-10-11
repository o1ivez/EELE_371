#include <msp430.h> 
//Oliver Gough, EELE 371, 4/4/24

int dataCount = 0;
char packet[] = {0x03, 0x00, 0x17, 0x13, 0x15, 0x07, 0x04, 0x24};

int main(void){
	WDTCTL = WDTPW | WDTHOLD;	//stop watchdog timer

	//--1 put eUSIC_B0 into software reset
	UCB0CTLW0 = UCSWRST;        //set for software reset

	//--2 configure eUSCI_B0
	UCB0CTLW0 |= UCSSEL_3;      //choose smclk, 1 meghaHZ
	UCB0BRW = 10;              //devide smclk by 10

	UCB0CTLW0 |= UCMODE_3;     //put into i2c mode
	UCB0CTLW0 |= UCMST;         //put into master mode
	UCB0CTLW0 |= UCTR;          //put into Tx mode
	UCB0I2CSA = 0x68;         //slave address = 0x68

	UCB0CTLW1 |= UCASTP_2;
	UCB0TBCNT = sizeof(packet);

	//--3 configure ports
	P1SEL1 &= ~BIT3;            //we want p1.3 = scl
	P1SEL0 |= BIT3;

	P1SEL1 &= ~BIT2;            //we want p1.2 = sda
	P1SEL0 |= BIT2;

	PM5CTL0 &= ~LOCKLPM5;       //disable lpm

	//--4 take eUSCI_B0 out of sw reset
	UCB0CTLW0 &= ~UCSWRST;      //take out of software reset

	//--5 enable interupts
	UCB0IE |= UCTXIE0;          //enable I2C Tx0 IRQ
	__enable_interrupt();       //enable maskable irqs

	int i;

	while(1){
	    UCB0CTLW0 |= UCTXSTT;   //generate start condition
	    for(i = 0; i< 100; i++){ //delay loop
	    }
	}
	
	return 0;
}
//-----------------------ENABLE IRQ---------------------------
#pragma vector=EUSCI_B0_VECTOR
__interrupt void EUSCI_B0_I2C_ISR(void){

    if(dataCount == (sizeof(packet)-1)){
        UCB0TXBUF = packet[dataCount];
        dataCount = 0;
    } else {
        UCB0TXBUF = packet[dataCount];
        dataCount ++;
    }

}
