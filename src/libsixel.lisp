;(multiple-value-bind (out err exc) 
;  (uiop:run-program "img2sixel --version" :output t :ignore-error-status t)
;  (if (/= exc 0) nil t))
  

(defmacro temp-basename (prefix)
  `(let ((a (write-to-string (get-universal-time)))
         (b (write-to-string (random 1000))))
         (format nil "~A-~A-~A" ,prefix a b)))


(defparameter +temp+ "/tmp")


(defparameter tex-template "\\documentclass[~A]{article}
\\usepackage{amsmath,amssymb}
\\usepackage{breqn}
\\pagestyle{empty}
\\begin{document}
 ~A
\\end{document}")

(defparameter latex-cmd 
"latex -jobname=~A --output-directory=~A -interaction=nonstopmode ~A")

(defparameter dvipng-cmd 
"dvipng -T ~A -D ~A -O ~A -fg ~A -bg ~A -q -o ~A ~A")

(defparameter image-to-sixel-cmd
"img2sixel ~A")

(defun write-tex-file (jobname tex &key (pt "11pt"))
  (let ((file-name (concatenate 'string +temp+ "/" jobname ".tex")))
    (with-open-file (texf file-name
        :direction :output
        :if-exists :supersede
        :if-does-not-exist :create)
        (format texf tex-template pt tex))))
        
(defun run-latex (jobname)
  (let* ((file-name (concatenate 'string +temp+ "/" jobname ".tex"))
        (cmd (format nil latex-cmd jobname +temp+ file-name)))
        (uiop:run-program cmd :output nil :ignore-error-status t)))
  

(defun run-dvipng (jobname fg bg res size off)
  (let* ((file-name (concatenate 'string +temp+ "/" jobname ".dvi"))
         (img (concatenate 'string +temp+ "/" jobname ".png")) 
         (cmd (format nil dvipng-cmd size res off fg bg img file-name)))
         (uiop:run-program cmd :output nil :ignore-error-status t)))


(defun run-img-to-sixel (jobname)
  (let* ((img (concatenate 'string +temp+ "/" jobname ".png"))
        (cmd (format nil image-to-sixel-cmd img)))
        (uiop:run-program cmd :output t :ignore-error-status t)))
        
(defun tidy-up (jobname) jobname) 
  ;(let ((cmd (format nil "rm ~A/~A.*" +temp+ jobname)))
    ;(uiop:run-program cmd :output nil :ignore-error-status t)))
       

(defun latex-to-sixel (tex  &key (pt "11pt") (fg "Green") (bg "Black") 
             (res "150") (size "bbox") (off "-1.0cm,-2.0cm"))
  (let* ((jobname (temp-basename "ltx2sixel")))
         (progn (write-tex-file jobname tex :pt pt)
                (run-latex jobname)
                (run-dvipng jobname fg bg res size off)
                (run-img-to-sixel jobname)
                (tidy-up jobname))))


;(uiop::run-program  "latex2sixel '$$\\alpha$$'" :output t )

(defparameter tex-test1 
"$$\\int_{\\Omega} d\\omega}=\\int_{\\partial\\Omega} \\omega$$")

;(latex-to-sixel tex-test1 :bg "White" :fg "Red" :size "18cm,4cm")
;(latex-to-sixel "$$Hello\\ \\LaTeX$$" :bg "White" :fg "Blue" :size "16cm,2cm")


  




 