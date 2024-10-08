# I2S-simultaneous-TDA1541A_Balanced
VHDL code for converting standard I2S data (64fs) to the offset-binary data (simultaneous) needed for TDA1541A DAC with Balanced mode

- "I2S 2x32=64-bit = 64fs" to "16-bit offset-binary" (simultaneous) with inverted MSB and stop-clocked BCK) for TDA1541A DAC (stereo) without the use of MCLK (= even less digital work)
- basic data synchronisation is incorporated on LRCK signal
- Balanced mode possible
- the sound is nice, clean, without digital interference
- my VHDL code is very simple, without advanced techniques, based mostly on standard logic
- therefore inexperienced users can understand and modify it for other similar DACs
- it has low load on the CPLD and it takes up little memory
- only 3 signal wires (I2S) are needed for input (DATA, BCK, LRCK).
- output is true offset-binary specified for TDA1541A in the simultaneous mode: 
 - -  CL  (outCL)  - stopped DAC clock
 - -  DL  (outDL)  - Left DAC data (inversed MSB)
 - -  DLi (outDLi) - Left DAC data inverted (inversed MSB)
 - -  LL  (outLL)  - Latch for left channels (latched together)
 - -  DR  (outDR)  - Right DAC data (inversed MSB)
 - -  DRi (outDRi) - Right DAC data inverted (inversed MSB)
 - -  LR  (outLR)  - Latch for right channels (latched together)
- it flawlessly works with the cheap CPLD EPM240T100C5 from aliexpress and can be easily configured for others
- my VHDL code is open and free for all

Tutorial how to programm CPLD: https://electrodac.blogspot.com/p/i2s-to-tda1541a-balanced-converter.html

Quartus project file: https://drive.google.com/file/d/1HbCrIXkTgO9RH4hVWMeN_8kdebNSMpK4/view?usp=sharing

If you like my work and find it helpful, you can donate coffee for me :D Donate Coffee for miro1360: https://www.buymeacoffee.com/miro1360coffee Thank you :)
