#include <msp430.h> 
//Oliver Gough, EELE 371, 4/1/24
//error == 12.89 mV

int ADC_Value;

int main(void)
{
    WDTCTL = WDTPW | WDTHOLD;   // stop watchdog timer

    //configure ports
    P1DIR |= BIT0;  //led 1 as out

    P1SEL1 |= BIT4; //configure P1.2 Pin for A2
    P1SEL0 |= BIT4;

    PM5CTL0 &= ~LOCKLPM5;

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
    __enable_interrupt();   // enable maskable irqs

       while(1){
           ADCCTL0 |= ADCENC | ADCSC;          //enable and start conversion
           __bis_SR_register(GIE | LPM0_bits); //enable maskable irqs, turn off cpu for lpm
       } // end while loop
       return 0;
   }//end main
//---------------------ISR-------------------------------
#pragma vector = ADC_VECTOR
__interrupt void ADC_ISR(void){
    __bic_SR_register_on_exit(LPM0_bits);   //wake up cpu
    ADC_Value = ADCMEM0;                //read adc result

//led ranges V<1 == low, 1<V<2 == mid, 2<V<3 == high, 3<V == extreme
    if(ADC_Value < 178){                      //if (A2 < 1v)
            P1OUT &= ~BIT0;                     //led 1 off
       } else {                              //if (A2 > 3v)
            P1OUT |= BIT0;                   //led 1 on
       }
}
