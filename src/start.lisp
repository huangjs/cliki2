(in-package #:cliki2)

;;; unreferenced uri checking
(dolist (unreferenced-uri (set-difference %referenced-uris %defined-uris
                                          :key #'car :test #'string-equal))
  (warn "Reference warning: referencing unknown URI resource ~a in file ~a"
        (car unreferenced-uri) (cdr unreferenced-uri)))

(defvar *cliki-server* nil)

(defun start-cliki-server (port homedir wikis)
  (if *cliki-server*
      (progn (warn "CLiki server already running")
             *cliki-server*)
      (progn
       ;; SBCL, CCL and possibly others always start w/same pseudo-random seed
        (setf *random-state* (make-random-state t))

        ;; set up HyperSpec paths
        (setf clhs-lookup::*hyperspec-pathname*
              (merge-pathnames "HyperSpec/" homedir)
              clhs-lookup::*hyperspec-map-file*
              (merge-pathnames "HyperSpec/Data/Symbol-Table.text" homedir)
              clhs-lookup::*hyperspec-root* "/site/HyperSpec/")

        (let ((error-log (merge-pathnames "error-log" homedir)))
          (open error-log :direction :probe :if-does-not-exist :create)
          (let ((acceptor
                 (make-instance
                  'cliki2-acceptor
                  :port                     port
                  :input-chunking-p         nil
                  :persistent-connections-p nil
                  :access-log-destination   nil
                  :message-log-destination  error-log
                  :wikis                    wikis
                  :dispatch-table
                  (list
                   (wiki-static-dispatcher)
                   (create-folder-dispatcher-and-handler
                    "/site/HyperSpec/" (merge-pathnames #p"HyperSpec/" homedir))
                   (create-static-file-dispatcher-and-handler
                    "/site/error-log" error-log "text/plain")
                   'dispatch-easy-handlers
                   'article-dispatcher))))
            (start acceptor)
            (setf *cliki-server* acceptor))))))
