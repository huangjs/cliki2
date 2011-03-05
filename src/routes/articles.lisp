;;;; articles.lisp

(in-package #:cliki2)

(restas:define-route view-article (":title")
  (or (article-with-title title)
      (make-instance 'article-not-found
                     :title title)))

(restas:define-route view-article-source ("raw/:title"
                                          :content-type "text/plain")
  (article-content (check-article title)))

(restas:define-route edit-article ("edit/:title")
  (check-article-edit-access)
  (make-instance 'edit-article-page
                 :title title
                 :article (article-with-title title)))

(restas:define-route save-article ("edit/:title"
                                   :method :post
                                   :requirement (check-edit-command "save"))
  (check-article-edit-access)
  (with-transaction ()
    (let ((article (or (article-with-title title)
                       (make-instance 'article :title title))))
      (push (make-instance 'revision
                           :content (hunchentoot:post-parameter "content")
                           :author *user*
                           :author-ip (hunchentoot:real-remote-addr))
            (article-revisions article))))
  (restas:redirect 'view-article
                   :title title))

(restas:define-route preview-article ("edit/:title"
                                      :method :post
                                      :requirement (check-edit-command "preview"))
  (check-article-edit-access)
  (make-instance 'preview-article-page
                 :title title
                 :content (hunchentoot:post-parameter "content")))


(restas:define-route cancel-edit-article ("edit/:title"
                                          :method :post
                                          :requirement (check-edit-command "cancel"))
  (check-article-edit-access)
  (restas:redirect 'view-article
                   :title title))

(restas:define-route view-article-history ("history/:(title)")
  (make-instance 'article-history-page
                 :article (check-article title)))

(restas:define-route view-article-revision ("history/:title/:mark")
  (let ((article (check-article title)))
    (make-instance 'article-revision-page
                   :article article
                   :revision (find mark
                                   (article-revisions article)
                                   :key #'revision-content-sha1
                                   :test #'string=))))
