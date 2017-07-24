# AVR APRS Controller

## Overview

The goal of this project is to implement an APRS controller with as few components as possible.  Essentially, I've taken the laptop and TNC you would normally need and squashed it into one inexpensive package.  The two main components are an AVR microcontroller and an MX-COM MX614 modem chip.

## Complete! (Added August 9, 2001)

Everything is working and I road tested it with success!  Unfortunately, the APRS coverage in Baton Rouge is not very good -- there are at best two fixed stations to digipeat through, and neither provide much coverage.   A full description is available here, but I still need to update the source code.  I also wrote a CGI to generate maps for my homepage.

## More Progress! (Added June 25, 2001)

The circuit is now 100% functional without the support of the development board.  I added a MAX233 chip to do level conversion from the GPS and also to supply power to the GPS (it has a built-in +10V charge pump which should be capable of powering most GPS's.  It'll work great since most mobile radios have a +5V supply included in the mic plug.).

All I have left is a few software changes (i.e., making the transmit interval speed dependent).  From there, I'll take it out on the road, make any final hardware changes, and then begin work on the PCB.

The design currently consists of three IC's (AVR, MX614, and MAX233), one crystal, three caps, and one resistor.  The final product will all use surface mount components.  It's gonna be small!  (I may need to add two pots to allow the Tx and Rx audio gain to be adjusted.)

## Progress! (Added June 4, 2001)

After a brief hiatus in development (due in part to my recovering from a very, very difficult semester), I've resumed work on the AVR-APRS.  I finished most of the code for my EE 4750 final project, the last things to do are:

Make the circuit function without the development board.
Put the final touches on the software.
Design and assemble a printed circuit board.
Add more features!

Task 1 is almost complete:

INSERT IMAGE HERE

The ribbon cable is strictly for power and programming 
the '4433.  The black and blue wires are TX audio and 
ground, going off to the TNC.  

##  Caveats

I built this project an independent project as part of my EE 4750 Microcontroller Interfacing class at LSU.  Due to time constraints (ie, an non-negotiable due date), I didn't get to implement everything I wanted (or make it as efficient as I wanted.  The report below is just a preliminary design.  I expect to come up with a PCB pattern so the unit can be self-contained an portable (and practical).  Stay tuned...!

##  Downloads

- serial.asm: Serial port routine. 
- lcd.asm: LCD driver routine.
- delay.asm: Brief delay.
- avraprs.asm: The main assembly file.
- Final Report: A brief overview of the project and all the standards/protocols that must be adhered to including APRS, NMEA, and AX.25. (Final because it was my final project at school, not because it's complete.)