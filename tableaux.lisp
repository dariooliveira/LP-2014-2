
(in-package :tableaux)


(defclass formula ()
  ((sign    :initform nil :initarg :sign :accessor formula-sign)
   (frm     :initform nil :initarg :frm  :accessor formula-frm)))

(defmethod print-object ((frm formula) stream)
  (format stream "<[~a] ~a>" (formula-sign frm) (formula-frm frm)))


(defun atomic? (formula)
  (not (listp (formula-frm formula))))

(defun invert-sign (sign)
  (if (equal sign 'true) 'false 'true))

(defun make-formula (sign wff)
  (make-instance 'formula :sign sign :frm wff))

(defun is? (op formula)
  (equal op (car (formula-frm formula))))

(defun sign? (sign formula)
  (equal sign (formula-sign formula)))


(defun cost (a-formula)
  (with-slots (sign frm) a-formula
    (match (list (car frm) sign)
      ('(and true)  1)
      ('(and false) 2)
      ('(or  true)  2)
      ('(or  false) 1)
      ('(implies true)  2)
      ('(implies false) 1)
      ((or '(not true) '(not false)) 1))))


(defun derive (branch)
  "Given a branch, select a formula to be decomposed according the rules."
  (if (remove-if #'atomic? branch)
      (let* ((frms (sort (remove-if #'atomic? branch) 
			 #'< :key #'cost))
	     (rest (remove (car frms) branch :test #'equal))) 
	(values (apply-rule (car frms)) rest))
      (values nil branch)))


(defun apply-rule (formula)
  "The [match] function from optima library provides pattern-matching
   functionality."
  (with-slots ((wff frm) sign) formula  
    (labels ((beta (s1 s2)
	       (list (list (make-formula s1 (cadr  wff))) 
		     (list (make-formula s2 (caddr wff)))))
	     (alfa (s1 s2)
	       (list (list (make-formula s1 (cadr  wff))
			   (make-formula s2 (caddr wff))))))
      (match (list (car wff) sign)
	('(and false)     (beta 'false 'false))
	('(and true)      (alfa 'true 'true)) 
	('(or true)       (beta 'true 'true))
	('(or false)      (alfa 'false 'false))
	('(implies false) (alfa 'true 'false))
	('(implies true)  (beta 'false 'true))
	((or '(not true) '(not false)) 
	 (list (list (make-formula (invert-sign sign) (cadr wff)))))))))


(defun unify (frm1 frm2)
  (and (atomic? frm2)
       (atomic? frm1)
       (equal (invert-sign (formula-sign frm1))
	      (formula-sign frm2))
       (equal (formula-frm frm1) 
	      (formula-frm frm2))))


(defun full-expanded? (branch)
  (every #'atomic? branch))


(defun expand-branch (frms branch)
  (if (null frms)  
      branch
      (let ((frm (car frms))
	    (res (cdr frms)))
	(if (find frm branch :test #'unify)
	    nil
	    (expand-branch res (cons frm branch))))))


(defun expand-branches (lolf branch branches)
  (if (null lolf) 
      branches
      (let ((newb (expand-branch (car lolf) branch)))
	(if newb 
	    (expand-branches (cdr lolf) branch (cons newb branches))
	    (expand-branches (cdr lolf) branch branches)))))


(defun prove-step (branches)
  (multiple-value-bind (news branch-rest)
      (derive (car branches))
    (expand-branches news branch-rest (cdr branches))))


(defun prove (wff)
  (do ((branches (list (list (make-formula 'false wff)))
		 (prove-step branches)))
      ((or (null branches)
	   (every #'full-expanded? branches)) 
       branches)))


(defun test ()
  (format t "~{~{~a ~^=> ~}~%~}" 
	  (mapcar (lambda (f) (list f (prove f))) 
		  (list '(and A B)
			'(or A B)
			'A
			'(implies (or A B) (and A B))
			'(implies (and A B) (or A B))
			'(implies (not (not A)) A)
			'(implies A (not (not A)))))))
