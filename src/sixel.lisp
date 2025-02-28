
#|

SIXEL ~~ SIX(PI)XEL 

1|  *  2^0 ->  1      Adding up this numbers for the pixels that are ON
2|  *  2^1 ->  2      yields a unique number between 0 (all OFF) and 63
3|  *  2^2 ->  4      (all ON). In order to obtain an ASCII character in 
4|  *  2^3 ->  8      the printable range (63 to 126) an offset of 63 is
5|  *  2^4 -> 16      added. Thus each of the following characters is a 
6|  *  2^5 -> 32      encoded vertical row of six pixels: 

* (loop for i from 63 to 126 collect (code-char i))
(#\? #\@ #\A #\B #\C #\D #\E #\F #\G #\H #\I #\J #\K #\L #\M #\N #\O #\P #\Q
 #\R #\S #\T #\U #\V #\W #\X #\Y #\Z #\[ #\\ #\] #\^ #\_ #\` #\a #\b #\c #\d
 #\e #\f #\g #\h #\i #\j #\k #\l #\m #\n #\o #\p #\q #\r #\s #\t #\u #\v #\w
 #\x #\y #\z #\{ #\| #\} #\~)
*

Enter sixel mode: #\Esc #\P #\q
Leave sixel mode: #\Esc #\\

  Example (three sixels = 3 vertical rows each six pixels all ON):
    
    (format t "~{~C~}" (list #\Esc #\P #\q #\~ #\~ #\~ #\Esc #\\)) 
  
Repeat sequence: #\! (#\d)* #\c   (d: digit, c: character to repeat)

  Example (repeat 55 times):
    
    (format t "~{~C~}" (list #\Esc #\P #\q #\! #\5 #\5  #\~ #\~ #\Esc #\\))

Suppose we want to set  pixel three and four to OFF. Adding 1,2,5 and 6 yields
1+2+16+32=51. This is the character (code-char (+ 51 63))=#\r. Hence

    (format t "~{~C~}" (list #\Esc #\P #\q #\! #\5 #\5 #\r #\~ #\Esc #\\))

Now we can see two thinner lines instead of one bold line.

The same coloured in RED:

  (format t "~{~C~}" (list #\Esc #\P #\q #\# #\1 #\; #\2 #\; #\1 #\0 #\0 #\; 
       #\0 #\; #\0    #\! #\5 #\5 #\r  #\Esc #\\))

   the newly added sequence is
   
      #\# #\1 #\; #\2 #\; #\1 #\0 #\0 #\; #\0 #\; #\0

   and has the following meaning:
   
   #\# ..... introduces color selection
   #\1 ..... is the color number to define (0..255) ; 0 is black by default?
   #\; ..... mandatory separator
   #\2 ..... selects RGB mode (#\1 would be HLS)
   #\; ..... mandatory separator
   #\1 #\0 #\0 .... means 100% RED
   #\0 #\; #\0 .... means 0% GREEN and 0% BLUE.
   
   after the last parameter a seaparator seems not to be required.
   
   
|#

(defun enter-sixel () (list #\Esc #\P #\q))
(defun leave-sixel () (list #\Esc #\\))
(defun carriage-return () (list #\$))
(defun new-line () (list #\-))


(defun int-to-chars (num) 
"Coerce an integer to a list of characters (digits)."
  (coerce (write-to-string num) 'list))

(defun repeat-char (chr num)
"Create a sixel repeat sequence for character chr, num times.
 Example: (repeat-char #\x 123) --> (#\! #\1 #\2 #\3 #\x)"
  (append  '(#\!) (int-to-chars num) (list chr)))
  
(defun define-color (pc pu px py pz)
"Defines a color for sixel output.  
 * pc is the color number to define 0-255,
 * pu=1 or 2 is the color coordinate system (HLS=1 or RGB=2)
 * px, py, and pz are the color coordinates in the specified system, where
 * HLS: px=0..360 (hue/deg), py=0..100 (lightness/%), pz=0..100 (saturation/%)
 * RGB: px,py,pz=0..100 (red,green,blue intensity in %)
 Example: (define-color 1 2 30 30 40), i.e. color#1:RGB:30:30:40%."
  (append '(#\#) 
     (int-to-chars pc) '(#\;) 
     (int-to-chars pu) '(#\;)
     (int-to-chars px) '(#\;) 
     (int-to-chars py) '(#\;) 
     (int-to-chars pz)))     


(defmacro display-sixel-data (s)
"Display sixel data, where data s is a list of characters without the 
enter- and leave sixel mode sequence.
Example: (display-sixel-data '(#\! #\5 #\5 #\9 #\r #\~))."
  `(format t "~{~C~}" (concatenate 'list (enter-sixel) ,s (leave-sixel))))

; (macroexpand '(display-sixel-data '(#\! #\5 #\5 #\r #\~)))
; (display-sixel-data '(#\! #\5 #\5 #\9 #\r #\~))

(defun pix-to-six-char (p1 p2 p3 p4 p5 p6)
"Return the character corresponding to the setting of the six pixels:
 Calculated as follows (code-char of): 63 + sum[2^(n-1)*p_n,n=1..6].
 Example:  (pix-to-six-char 1 1 0 0 1 1) --> #\r."
  (code-char (+ 63 p1 (* 2 p2) (* 4 p3) (* 8 p4) (* 16 p5) (* 32 p6))))


(defun raster-attributes (pan pad ph pv)
"This command selects the raster attributes for the sixel data string that 
 follows it. You must use the command before any sixel data string.
 * Pan and Pad define the pixel aspect ratio (pan/pad) for the sixel data 
   string following. Pan is the numerator, and Pad is the denominator.
 * Pan defines the vertical shape of the pixel. Pad defines the horizontal 
   shape of the pixel. For example, to define a pixel that is twice as high 
   as it is wide, you use a value of 2 for Pan and 1 for Pad.
 * Ph and Pv define the horizontal and vertical size of the image (in pixels), 
   respectively."
(append  '(#\") (int-to-chars pan) '(#\;) 
                (int-to-chars pad) '(#\;)    
                (int-to-chars ph)  '(#\;) 
                (int-to-chars pv)))
                  
  
(defun create-raster (horiz vert char)
  (loop for v from 1 to vert collect
    (loop for h from 1 to horiz collect char)))

                  
;;; (display-sixel-data (test1))
;;; should show some lines in red, green, blue, each 500 pixels long.
;;; test1 creates three sixels veetically, so we have 18 pixels width.
(defun test1 ()
  (concatenate 'list
    (define-color 2 2 100 0 0)
    (repeat-char #\r 500)
    (new-line)
    (define-color 3 2 0 100 0)
    (new-line)
    (repeat-char #\s 500)
    (new-line)
    (define-color 4 2 0 0 100)
    (repeat-char #\t 500)))






(documentation 'define-color 'function)
(documentation 'pix-to-six-char 'function)







