#include <msp430.h> 
//Oliver Gough, EELE 371, 3/24/24

//error estimates
// 3752 @3v, 22.85 mV error
// 2509 @2v, 21.14 mV error
// 1267 @1v, 20.77 mV error
// max resoltuion error = 805.64 uV
// adc dc error #32 == 25.78 mV, reletivle close so we can contribute, value also fluctuates within this range.

int ADC_Value;
int main(void)
{
    WDTCTL = WDTPW | WDTHOLD;   // stop watchdog timer

    //configure ports
    P1DIR |= BIT0;  //set as out
    P6DIR |= BIT6;

    P1SEL1 |= BIT2; //configure P1.2 Pin for A2
    P1SEL0 |= BIT2;

    PM5CTL0 &= ~LOCKLPM5;

    //configure adc
    ADCCTL0 &= ~ADCSHT;     //clear adcsht from def. of ADCSHT =01
    ADCCTL0 |= ADCSHT_2;    //conversion cycles = 16 (ADCSHT = 10)
    ADCCTL0 |= ADCON;       //turn adc on

    ADCCTL1 |= ADCSSEL_2;   //adc clock source = SMCLK
    ADCCTL1 |= ADCSHP;      //Sample signal source = sampling timer

    ADCCTL2 &= ~ADCRES;     //clear adc res from def. of ADCRES = 01
    ADCCTL2 |= ADCRES_2;    //resoltion  = 12-bit (ADCRES = 10)

    ADCMCTL0 |= ADCINCH_2;  //adc input chanel = A2 (p1.2)

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
    if(ADC_Value < 1241){                      //if (A2 < 1v)
            P1OUT &= ~BIT0;                     //led 1 off
            P6OUT &= ~BIT6;                     //led 2 on
        } else if((1241 < ADC_Value)&(ADC_Value < 2482)){    //if (A2 > 1v)
            P1OUT &= ~ BIT0;                    //led 1 off
            P6OUT |= BIT6;                      //led 2 on
       } else if((2482 < ADC_Value)&(ADC_Value < 3723)){      //if (A2 > 2v)
           P1OUT |= BIT0;                    //led 1 on
           P6OUT &= ~BIT6;                   //led 2 off
       } else {                              //if (A2 > 3v)
            P1OUT |= BIT0;                   //led 1 on
            P6OUT |= BIT6;                   //led 2 on
       }
}
