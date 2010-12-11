SkimFlip
========

SkimFlip is an accelerometer driven document rotation applet that works with the free PDF reader Skim that rotates the PDF document to match the orientation with which a Macbook or Modbook is held.

Description
-----------
When launched, this Applescript applet automatically rotates a PDF document in Skim to match the orientation at which the notebook is held. It is designed with the [Axiotron Modbook][] (a modification of an Apple MacBook) in mind, but works with an ordinary MacBook as well. (Note that SkimFlip will not work in the eleven or thirteen inch MacBook Airs of October 2010 since neither notebook has a sudden motion sensor.) 

Requirements
------------
An Apple MacBook or Axiotron Modbook running either Leopard or Snow Leopard. (Tested on OSX 10.5.8 & OSX 10.6.5)

Installation
------------
After pulling or downloading the branch from GitHub, running the AppleScript `AScompile.scpt` will compile the `SkimFlip.scpt`, its associated utilities, and arrange any other needed resources into a working applet: `SkimFlip.app`.

Usage
-----
The use is straightforward. The orientation of the document is rotated to match the users orientation of the notebook. There are, however, a few refinements.  

- A modest (about 20 degree) tilt to the right advances the document to the next page. Similarly, a modest tilt to the left goes to the document's previous page. More pronounced tilts (about 30 degrees), turn the pages more rapidly. 
- If you've changed pages recently, but now want to flip back to your last reading place, turn the notebook over with display/base facing down briefly (until you hear a tink) and the document will return to your previous spot.
-  Turn the notebook over with display/base facing down for a count of of three (until you hear a submarine sound that follows the tink), you will see a dialog box:

![Dialog Box][]

+ Choosing the box's default option, "Pause SkimFlip", will suspend SkimFlip so that you can tip your Modbook as you wish without any document rotation or page turning. Flipping your Modbook over again for a count of three will reactivate SkimFlip.

+ Choosing the "Turn Pages with Stylus" option, disables the ability to turn pages by tilting. I often put SkimFlip in this state when riding on the bus to prevent unwanted page changes. (One can still turn pages in Skim's Full Screen and Presentation Mode by putting the pen near the bottom of the display and using the interface that pops up). To re-enable page change by tilting, flip your Modbook upside down again for a count of three.

+ The last option, "Send Escape key", just sends Skim an escape keystroke, which is useful for exiting Full Screen or Presentation Mode if a keyboard isn't handy. 

That is all there is to it, but a couple caveats are in order. First, SkimFlip only works when Skim is the frontmost application. When you are using other apps, SkimFlip hibernates (this is also a quick way to pause SkimFlip). In addition, SkimFlip seems to work best when Skim's view settings are set to "Automatically Resize", but NOT set to "Continuous". 

![Skim Settings][]

Finally, since SkimFlip needs to respond to small changes in Modbook orientation, it is important to make sure that the Sudden Motion Sensor (the accelerometer) in your Modbook is properly calibrated. [SeisMaCalibrate][] makes SMS calibration a simple, five minute process. It is well worth the effort. 


Credits and Licenses
--------------------
The MacFlip script was written by [Eric Nitardy][ericn] (©2010). It is also available for download from [Modbookish][] and may be modified and redistributed in accordance with the `License.txt` file.

The script uses the Unix utility smsutil and library smslib written by Daniel Griscom (©2007-2010). Please read the accompanying `smsutilCREDITS.txt` and `smsutilLICENSE.txt` file in the Resources folder for more information or visit his web site at [http://www.suitable.com][suitable] 



[Axiotron Modbook]: http://www.axiotron.com/index.php?id=modbook
[Dialog Box]: http://dl.dropbox.com/u/6347985/Modbookish/SkimFlip/Screenshot20100312at3121010.49.55AM1.png
[Skim Settings]: http://dl.dropbox.com/u/6347985/Modbookish/SkimFlip/SkimSettings1.png
[SeisMaCalibrate]: http://www.suitable.com/tools/seismacalibrate.html
[Modbookish]: http://modbookish.lefora.com/2010/04/23/skimflip-accelerometer-based-document-rotation-for/
[suitable]: http://www.suitable.com
[ericn]: http://modbookish.lefora.com/members/ericn/