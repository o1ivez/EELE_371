#include <msp430.h> 

/**
 * Ben Weizenegger, Oliver Gough, EELE 371, Project 8
 *  4/22/2024
 *
 *  Calculated number of steps: 32 * (64.128) = 2052 steps/revolution (Stepper Motor Datasheet)
 *
 *  15 sec Clk: 2052/15 = 136.8step/sec | 1/136.8 = .0073sec/step
 *
 *  CCR0 = .0073/((1/1000000)*7*4) = 260.7 adjusted to 271 when testing
 *
 *  Max RPM = 6 RPM
 *  15 * (2/3) = 10sec clk
 *
 *  271* (2/3) = 180 adjusted to 178
 *
 */

/**
 * main.c
 */

char openMessage[] = "\n\rGate was OPENED at: ";
char closedMessage[] = "\n\rGate was CLOSED at: ";
int sw;
unsigned int position;
int i, j;
char packet[] = {0x03, 0x00, 0x17, 0x13, 0x1, 0x07, 0x05, 0x24};
char Received[7];
int dataCount = 0;
int cycle = 0;
int clkEnable = 0;
int voltageEnable, motorEnable = 0;
int carEnable = 1;
int ADC_Value;

int main(void)
{

    WDTCTL = WDTPW | WDTHOLD;   // stop watchdog timer
    //---------------digital IO setup----------------------

    //p5.0 led out
    P5DIR |= BIT0;          //set led as out
    P5OUT &= ~BIT0;         //clear led to start
    P5REN |= BIT0;          //enable resistor
    P5OUT &= ~BIT0;         //set as pull down

    //p5.1 led out
    P5DIR |= BIT1;          //set led as out
    P5OUT &= ~BIT1;         //clear led to start
    P5REN |= BIT1;          //enable resistor
    P5OUT &= ~BIT1;         //set as pull down

    //p5.2 led out
    P5DIR |= BIT2;          //set led as out
    P5OUT &= ~BIT2;         //clear led to start
    P5REN |= BIT2;          //enable resistor
    P5OUT &= ~BIT2;         //set as pull down

    //p5.3 led out
    P5DIR |= BIT3;          //set led as out
    P5OUT &= ~BIT3;         //clear led to start
    P5REN |= BIT3;          //enable resistor
    P5OUT &= ~BIT3;         //set as pull down

    //p4.1 switch 1 in
    P4DIR &= ~BIT1;         //configure p4.1 sw1 as in
    P4REN |= BIT1;          //enable resistor
    P4OUT |= BIT1;          //set as pull up resistor
    P4IES |= BIT1;          //configure irq h-to-l

    //p2.3 switch 2 in
    P2DIR &= ~BIT3;         //configure p2.3 sw2 as out
    P2REN |= BIT3;          //enable resistor
    P2OUT |= BIT3;          //set as pull up resistor
    P2IES |= BIT3;          //configure h-to-l

    //set p5 out for wavegen
    P5OUT = 0;              //set p5 out wave drive init

    //-- UART ---------------------------------------------------------------------------
    UCA1CTLW0 |= UCSWRST;       // Put eUSCI_A1 into SW reset

    //-- Configure eUSCI_A1
    UCA1CTLW0 |= UCSSEL__SMCLK;  //SMCLOCK

    UCA1BRW = 17;
    UCA1MCTLW |= 0x4A00;

    //-- Configure Ports

    P4SEL1 &= ~BIT3;            // Configure ports
    P4SEL0 |= BIT3;

    P2DIR &= ~BIT3;             //Switch 2
    P2REN |= BIT3;
    P2OUT |= BIT3;
    P2IES |= BIT3;


    P4DIR &= ~BIT1;             //Switch 1
    P4REN |= BIT1;
    P4OUT |= BIT1;
    P4IES |= BIT1;

    //----------------------ADC Setup----------------------
    //configure adc
    ADCCTL0 &= ~ADCSHT;     //clear adcsht from def. of ADCSHT =01
    ADCCTL0 |= ADCSHT_2;    //conversion cycles = 16 (ADCSHT = 10b)
    ADCCTL0 |= ADCON;       //turn adc on

    ADCCTL1 |= ADCSSEL_2;   //adc clock source = SMCLK
    ADCCTL1 |= ADCSHP;      //Sample signal source = sampling timer

    ADCCTL2 &= ~ADCRES;     //clear adc res from def. of ADCRES = 01
    ADCCTL2 |= ADCRES_0;    //resoltion  = 8-bit (ADCRES = 00b)

    ADCMCTL0 |= ADCINCH_4;  //adc input chanel = A4 (p1.4)

    ADCIE |= ADCIE0;        //enable adc conv complete irq

    //--------------------Timer Setup----------------------
    TB0CTL |= TBCLR;
    TB0CTL |= TBSSEL__SMCLK;//source = SMCLK
    TB0CTL |= MC__UP;       //mode = up
    TB0CTL |= ID__4;        //divide by 4
    TB0EX0 |= TBIDEX__7;    //divide by 7
    TB0CCR0 = 271;          //CCR0 = 271

    //-- I2C -----------------------------------------------------------------------------
    //-- Software Reset
    UCB0CTLW0 |= UCSWRST;       // UCSWRST = 1 for SW reset

    UCB0CTLW0 |= UCSSEL_3;      // SMCLK
    UCB0BRW = 10;

    UCB0CTLW0 |= UCMODE_3;      // I2C Mode
    UCB0CTLW0 |= UCMST;         // Master Mode
    UCB0CTLW0 |= UCTR;
    UCB0I2CSA = 0x0068;        // 68 Slave Address

    UCB0CTLW1 |= UCASTP_2;
    UCB0TBCNT = sizeof(packet);           // Send 1 BYTE

    P1SEL1 &= ~BIT2;            // P1.3 SCL
    P1SEL0 |= BIT2;

    P1SEL1 &= ~BIT3;            // P1.2 SDA
    P1SEL0 |= BIT3;
    //-- Enable Interrupts ----------------------------------------------------------------
    PM5CTL0 &= ~LOCKLPM5;

    //--  Take eUSCI_A1 out of software reset
    UCA1CTLW0 &= ~UCSWRST;

    //-- Enable IRQs
    P4IFG &= ~BIT1;
    P4IE |= BIT1;
    P2IFG &= ~BIT3;
    P2IE |= BIT3;

    //timer B0 interupt
    TB0CCTL0 |= CCIE;       //enable TB0 CCR0 Overflow IRQ
    TB0CCTL0 &= ~CCIFG;     //clear CCR0 flag

    UCB0CTLW0 &= ~UCSWRST;

    UCB0IE |= UCRXIE0;
    UCB0IE |= UCTXIE0;
    __enable_interrupt();


    int x;
    UCB0CTLW0 |= UCTXSTT;
    for(x=0; x<20000; x=x+1){}

    while (1) {
        //ADC start code
        ADCCTL0 |= ADCENC | ADCSC;                                 //enable and start conversion
        __bis_SR_register(GIE | LPM0_bits);                        //enable maskable irqs, turn off cpu for lpm
        //motor enable code
        if((voltageEnable == 1)&&(carEnable == 1)){                //sw1 clockwise condition
            openGateSlow();                                        //call open gate fnct
            voltageEnable = 0;                                     //reset enable
        }
        if((voltageEnable == 2)&&(carEnable == 0)){                //sw1 clockwise condition
            closeGateFast();
            voltageEnable = 0;                                     //reset enable
        }
        while(clkEnable == 1){
            //-- SEND DATA
            UCB0CTLW0 |= UCTR;
            UCB0TBCNT = 1;
            UCB0CTLW0 |= UCTXSTT;

            while ((UCB0IFG & UCSTPIFG) == 0);
            UCB0IFG &= ~UCSTPIFG;

            //-- RECEIVE DATA
            UCB0CTLW0 &= ~UCTR;
            UCB0TBCNT = 7;
            UCB0CTLW0 |= UCTXSTT;
            while ((UCB0IFG & UCSTPIFG) == 0);
            UCB0IFG &= ~UCSTPIFG;
        }
    }

    return 0;
}

//-- Interrupt Service Routines -------------------------------------------------------
//-- I2C ------------------------------------------------------------------------------
#pragma vector=EUSCI_B0_VECTOR
__interrupt void EUSCI_B0_I2C_ISR(void) {

    if (cycle < 9){
        if(dataCount == sizeof(packet)-1) {
            UCB0TXBUF = packet[dataCount];
            dataCount = 0;
        } else {
            UCB0TXBUF = packet[dataCount];
            dataCount++;
        }
        cycle++;
    }
    if (cycle == 9){
        switch(UCB0IV){
        case 0x16:
            Received[dataCount] = UCB0RXBUF;
            if(dataCount == (sizeof(Received)-1)) {
                dataCount = 0;
            } else {
                dataCount++;
            }
            break;

        case 0x18:
            UCB0TXBUF = 0x03;
            break;
        }
        clkEnable = 0;
    }
}
//-- END I2C --------------------------------------------------------------------------
//-- Switch 1 ----------------------------------------------------------------------------
#pragma vector = PORT4_VECTOR
__interrupt void ISR_Port4_ISR(void)
{
    clkEnable = 1;
    position = 0;                           // start position at 0
    sw = 1;
    UCA1IE |= UCTXCPTIE;
    UCA1IFG &= ~UCTXCPTIFG;
    UCA1TXBUF = closedMessage[position];        // first char
    for(i=0; i<5000; i=i+1){}

    P4IFG &= ~BIT1;
}
//-- END Switch 1 --------------------------------------------------------------------------------

//-- Switch 2 ------------------------------------------------------------------------------------
#pragma vector = PORT2_VECTOR
__interrupt void ISR_Port2_ISR(void)
{
    clkEnable = 1;
    position = 0;               // Start position at end of first namne
    sw=0;
    UCA1IE |= UCTXCPTIE;
    UCA1IFG &= ~UCTXCPTIFG;
    UCA1TXBUF = openMessage[position];             // first char
    for(i=0; i<5000; i=i+1){}


    P2IFG &= ~BIT3;
}

//-- END Switch 2 -------------------------------------------------------------------------------

#pragma vector = EUSCI_A1_VECTOR
__interrupt void ISR_EUSCI_A1(void)
{
    if (sw == 1){
        if(position == sizeof(closedMessage)-1) {           // Print First name if Switch 1
            UCA1TXBUF = ((Received[4] & 0xF0)>>4) + '0';    // Hours 10s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = (Received[4] & 0x0F) + '0';         // Hours 1s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ':';
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ((Received[3] & 0xF0)>>4) + '0';    // Minutes 10s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = (Received[3] & 0x0F) + '0';         // Minutes 1s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ':';
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ((Received[2] & 0xF0)>>4) + '0';    // Seconds 10s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = (Received[2] & 0x0F) + '0';         // Seconds 1s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ' ';
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ((Received[0] & 0xF0)>>4) + '0';    // Month 10s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = (Received[0] & 0x0F) + '0';         // Month 1s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = '/';
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ((Received[5] & 0xF0)>>4) + '0';    // Day 10s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = (Received[5] & 0x0F) + '0';         // Day 1s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = '/';
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ('2');
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = '0';
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ((Received[1] & 0xF0)>>4) + '0';    // Year 10s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = (Received[1] & 0x0F) + '0';         // Year 1s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = '\n';                               // Newline character
            for (i=0; i<100; i++){}
            UCA1TXBUF = '\r';                               // Carriage return (align-L)
            UCA1IE &= ~UCTXCPTIE;
        }  else if(position < sizeof(closedMessage)-1){
            position++;
            UCA1TXBUF = closedMessage[position];
        }
    } else if (sw == 0){
        if(position == sizeof(openMessage)-1) {                 // Print last name if Switch 2
            UCA1TXBUF = ((Received[4] & 0xF0)>>4) + '0';    // Hours 10s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = (Received[4] & 0x0F) + '0';         // Hours 1s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ':';
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ((Received[3] & 0xF0)>>4) + '0';    // Minutes 10s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = (Received[3] & 0x0F) + '0';         // Minutes 1s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ':';
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ((Received[2] & 0xF0)>>4) + '0';    // Seconds 10s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = (Received[2] & 0x0F) + '0';         // Seconds 1s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ' ';
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ((Received[0] & 0xF0)>>4) + '0';    // Month 10s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = (Received[0] & 0x0F) + '0';         // Month 1s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = '/';
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ((Received[5] & 0xF0)>>4) + '0';    // Day 10s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = (Received[5] & 0x0F) + '0';         // Day 1s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = '/';
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ('2');
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = '0';
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = ((Received[1] & 0xF0)>>4) + '0';    // Year 10s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = (Received[1] & 0x0F) + '0';         // Year 1s digit
            for (i = 0; i < 500; i++){}
            UCA1TXBUF = '\n';                               // Newline character
            for (i=0; i<100; i++){}
            UCA1TXBUF = '\r';                               // Carriage return (align-L)                                  // Carriage return (align-L)
            UCA1IE &= ~UCTXCPTIE;
        } else if(position < sizeof(openMessage)){
            position++;
            UCA1TXBUF = openMessage[position];
        }
    }
    UCA1IFG &= ~UCTXCPTIFG;
}


//-- END Interrupt Service Routines ---------------------------------------------------
//---------------Timer B0 Start-----------------------
#pragma vector = TIMER0_B0_VECTOR
__interrupt void ISR_TB0_CCR0(void){
    clkEnable = 1;
    motorEnable = 1;
    TB0CCTL0 &= ~CCIFG;
}
//----------------Timer ISR END------------------------
//--------------------ADC ISR Start--------------------
#pragma vector = ADC_VECTOR
__interrupt void ADC_ISR(void){              //1.5 = (2^8x116)/3.3 max = 186.18
    __bic_SR_register_on_exit(LPM0_bits);    //wake up cpu
    ADC_Value = ADCMEM0;                     //read adc result
    if(ADC_Value > 186){
        ADC_Value = 186;                     //implementing max voltage limit
    }
    if(ADC_Value > 116){                     //if (A2 < 1.5v)
        voltageEnable = 1;                   //open switch enable code
    }
    if (ADC_Value < 100) {                   //if (A2 > 1.5 v)
        voltageEnable = 2;                   //close switch enable code
    }
}
//--------------------ADC ISR END-----------------------
//---------------------Functions-----------------------
//------------------Open Gate Start--------------------
void openGateSlow(){

    i = 0;                                    //reset counter
    TB0CCR0 = 271;                            //CCR0 = 271
    P5OUT = 0b00000001;                       //set out register
    while(i < 2052){                          //set to run 12 times bc 1 full rotate is 4 and need 3 for demo 3x4 = 12
        if(P5OUT == 0b00010000){
            P5OUT = 0b00000001;               //reset P5OUT in case of overflow of rotate past the 4 leds
        }
        if(motorEnable == 1){
            P5OUT = P5OUT << 1;               //rotate P5OUT once
            motorEnable = 0;                    //reset clock enable and wait for clock
            i++;                              //increment counter
        }
    }
    carEnable = 0;                            //turns off after 1 car
    P5OUT = 0b00000000;                       //turn off after running
    P2IFG |= BIT3;

    return;
}
//------------------Open Gate End---------------------
//-----------------Close Gate Start-------------------
void closeGateFast(){
    i = 0;                                    //reset counter
    TB0CCR0 = 178;                            //CCR0 = 178
    P5OUT = 0b00001000;                       //set out register
    while(i < 2052){                          //set to run 12 times bc 1 full rotate is 4 and need 3 for demo 3x4 = 12
        if(P5OUT == 0b00000000){
            P5OUT = 0b00001000;               //reset P5OUT in case of overflow of rotate past the 4 leds
        }
        if(motorEnable == 1){
            P5OUT = P5OUT >> 1;               //rotate P5OUT once
            motorEnable = 0;                  //reset clock enable and wait for clock
            i++;                              //increment counter
        }
    }
    carEnable = 1;                            //turns on after 1 car
    P5OUT = 0b00000000;                       //turn off after running
    P4IFG |= BIT1;
    return;
}
//-------------------Close Gate End-------------------
//--------------------END Functions-------------------
