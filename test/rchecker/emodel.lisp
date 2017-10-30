(in-package :rchecker)
(defparameter *tasks*
  (list
   (list (for
          (fnot (fhas-key "agents"))
          (fand (fhas-kv "agents" 2 #'(lambda(js-val val)(< (length js-val) val)))))
         #'(lambda(model)(let ((res (funcall (eagent-new))))
                           (list res (if (second res)
                                         (jsown:extend-js (copy-tree model)
                                           ("agents" (list* (jsown:extend-js (first res)
                                                              ("state" "offline"))
                                                            (when (jsown:keyp model "agents")
                                                              (jsown:val model "agents")))))
                                         model))))
         "create agent")

   (list (fand (fhas-key "agents")
               (fhas-kv "agents" 0 #'(lambda(js-val val)(> (length js-val) val))))
         #'(lambda(model)(let ((res (funcall (tstep-result "Select the latest agent." 0 t "Select the latest agent." nil))))
                           (list res (if (second res)
                                         (jsown:extend-js (copy-tree model) ("selected-agent" 0))
                                         model))))
         "select last agent")
   (list (fand (fhas-key "agents")
               (fhas-key "selected-agent")
               (fcompare-keys "selected-agent" "agents" #'(lambda(selected items)(< (1+ selected) (length items)))))
         #'(lambda(model)(let* ((next (1+ (jsown:val model "selected-agent")))
                                (res (funcall (tstep-result "Select previous agent" next t "Select previous agent" nil))))
                           (list res (if (second res)
                                         (jsown:extend-js (copy-tree model) ("selected-agent" next))
                                         model))))
         "select next agent")

   (list (fand
          (fand (fhas-key "tasks")
                #'(lambda(model) (some (fhas-kv "state" "waiting" #'equal)
                                        (jsown:val model"tasks"))))
          (fhas-key "selected-agent")
          (fnth "selected-agent" "agents"
                (fnot (for
                       (fhas-kv "state" "ready" #'equal)
                       (fhas-kv "state" "busy" #'equal)))))
         #'(lambda(model)
             (let* ((selected (jsown:val model "selected-agent"))
                    (agents (jsown:val model "agents"))
                    (tasks (jsown:val model "tasks"))
                    (agent (nth selected agents))
                    (task-position (position-if (fhas-kv "state" "waiting" #'equal) tasks :from-end t))
                    (task (nth task-position tasks))
                    (res (funcall (eagent-set :id (jsown:val agent "id") :state "ready"))))
               (list res (if (second res)
                             (jsown:extend-js (copy-tree model)
                               ("agents" (set-nth selected (copy-tree agents)
                                                  (jsown::extend-js agent ("state" "busy")) ))
                               ("tasks" (set-nth task-position (copy-tree tasks)
                                                 (jsown::extend-js task ("state" "assigned")
                                                                   ("agent-id" (jsown:val agent "id"))))))
                             model))))
         "set-agent ready if there are waiting tasks")

   (list (fhas-key "selected-agent")
         #'(lambda(model)(let* ((selected (jsown:val model "selected-agent"))
                                (agents (jsown:val model "agents"))
                                (agent (nth selected agents))
                                (res (funcall (twait
                                               (eagent :id (jsown:val agent "id") :checks (has-kv "state" (jsown:val agent "state")))
                                               :timeout 10))))
                           (list res model)))
         "check agent state")

   (list (fand
          (fhas-key "selected-agent")
          (fnth "selected-agent" "agents"
                (fnot (fhas-kv "state" "busy" #'equal))))
         #'(lambda(model)(let* ((selected (jsown:val model "selected-agent"))
                                (agents (jsown:val model "agents"))
                                (agent (nth selected agents))
                                (res (funcall (eagent-del :id (jsown:val agent "id")))))
                           (list res (if (second res)
                                         (jsown:remkey (jsown:extend-js(copy-tree model)
                                                         ("agents" (remove-nth selected (copy-tree agents))))
                                                       "selected-agent")
                                         model))))
         "delete agent")

;; tasks
   (list (fand
          (for
           (fnot (fhas-key "tasks"))
           (fand (fhas-kv "tasks" 5 #'(lambda(js-val val)(< (length js-val) val)))))
          (for
           (fnot (fhas-key "agents"))
           (fand (fhas-key "agents") #'(lambda(model) (every #'(lambda(task)(not (equal (jsown:val task "state") "ready")))
                                                             (jsown:val model "agents")))) ))
         #'(lambda(model)(let* ((waiting-tasks (if (jsown:keyp model "tasks")
                                                   (length (remove-if-not
                                                            (fhas-kv "state" "waiting" #'equal)
                                                            (jsown:val model "tasks")))
                                                   0))
                                (res (funcall (tand (twait (equeue-size
                                                            :description (format nil "There should be ~A tasks in the queue" waiting-tasks)
                                                            :checks (check-and (has-json) (has-key "size")
                                                                                           (has-kv "size" waiting-tasks))))
                                                    (etask-new :checks (check-and (has-json) (has-key "id")
                                                                                  (has-kv "queueTasks" waiting-tasks)))))))
                           (list res (if (second res)
                                         (jsown:extend-js (copy-tree model)
                                           ("tasks" (list* (jsown:extend-js
                                                               (first res)
                                                             ("state" "waiting") )
                                                           (when (jsown:keyp model "tasks")
                                                             (jsown:val model "tasks")))))
                                         model))))
         "create task when there are no ready agents")

   (list (fand
          (for
           (fnot (fhas-key "tasks"))
           (fand (fhas-kv "tasks" 5 #'(lambda(js-val val)(< (length js-val) val)))))
          (fand (fhas-key "agents") #'(lambda(model) (some (fhas-kv "state" "ready" #'equal)
                                                           (jsown:val model "agents")))))
         #'(lambda(model)
             (let* ((waiting-tasks (if (jsown:keyp model "tasks")
                                       (length (remove-if-not
                                                (fhas-kv "state" "waiting"
                                                         #'equal)
                                                (jsown:val model "tasks")))
                                       0))
                    (agents (jsown:val model "agents"))
                    (agent-pos (position-if (fhas-kv "state" "ready" #'equal)
                                            agents))
                    (res (funcall (tand
                                   (twait (equeue-size
                                           :description (format nil "There should be ~A tasks in the queue" waiting-tasks)
                                           :checks (check-and (has-json) (has-key "size")
                                                              (has-kv "size" waiting-tasks))))
                                   (etask-new :checks (check-and (has-json) (has-key "id")
                                                                 (has-kv "queueTasks" waiting-tasks))))))
                    (agent (nth agent-pos agents)))
               (list res (if (second res)
                             (jsown:extend-js (copy-tree model)
                               ("tasks" (list* (jsown:extend-js
                                                   (first res)
                                                 ("state" "assigned")
                                                 ("agent-id" (jsown:val agent "id")))
                                               (when (jsown:keyp model "tasks")
                                                 (jsown:val model "tasks"))))
                               ("agents" (set-nth agent-pos (copy-tree agents)
                                                  (jsown::extend-js agent ("state" "busy")) )))
                             model))))
         "create task when there are ready agents")

   (list (fand (fhas-key "tasks")
               (fhas-kv "tasks" 0 #'(lambda(js-val val)(> (length js-val) val))))
         #'(lambda(model)(let ((res (funcall (tstep-result "Select the latest task." 0 t "Select the latest task." nil))))
                           (list res (if (second res)
                                         (jsown:extend-js (copy-tree model) ("selected-task" 0))
                                         model))))
         "select last task")
   (list (fand (fhas-key "tasks")
               (fhas-key "selected-task")
               (fcompare-keys "selected-task" "tasks" #'(lambda(selected tasks)(< (1+ selected) (length tasks)))))
         #'(lambda(model)(let* ((next (1+ (jsown:val model "selected-task")))
                                (res (funcall (tstep-result "Select previous task." next t "Select the previous task." nil))))
                           (list res (if (second res)
                                         (jsown:extend-js (copy-tree model) ("selected-task" next))
                                         model))))
         "select next task")

   (list (fhas-key "selected-task")
         #'(lambda(model)(let* ((selected (jsown:val model "selected-task"))
                                (tasks (jsown:val model "tasks"))
                                (task (nth selected tasks))
                                (res (funcall (twait (etask :id (jsown:val task "id")
                                                            :state (jsown:val task "state"))
                                                     :timeout 10))))
                           (list res model)))
         "check task state")

   (list (fand
          (fhas-key "selected-task")
          (fnth "selected-task" "tasks" (fhas-kv "state" "assigned" #'equal)))
         #'(lambda(model)(let* ((selected (jsown:val model "selected-task"))
                                (tasks (jsown:val model "tasks"))
                                (task (nth selected tasks))
                                (agent-id (jsown:val task "agent-id"))
                                (agents (jsown:val model "agents"))
                                (agent-pos (position-if #'(lambda(agent) (equal (jsown:val agent "id") agent-id))
                                                        agents))
                                (agent (nth agent-pos agents))
                                (res (funcall (etask-set :id (jsown:val task "id")
                                                         :state "completed"))))
                           (list res (if (second res)
                                         (jsown:extend-js (copy-tree model)
                                           ("agents" (set-nth agent-pos (copy-tree agents)
                                                              (jsown::extend-js agent ("state" "ready")) ))
                                           ("tasks" (set-nth selected (copy-tree tasks)
                                                             (jsown::extend-js task ("state" "completed")
                                                                               ("agent-id" ())))))
                                         model))))
         "complete task")

   (list (fand
          (fhas-key "selected-task")
          (fnth "selected-task" "tasks" (for(fhas-kv "state" "completed" #'equal)
                                            (fhas-kv "state" "waiting" #'equal)))
          )
         #'(lambda(model)(let* ((selected (jsown:val model "selected-task"))
                                (tasks (jsown:val model "tasks"))
                                (res (funcall (etask-del :id (jsown:val (nth selected tasks) "id")))))
                           (list res (if (second res)
                                         (jsown:remkey (jsown:extend-js(copy-tree model)
                                                         ("tasks" (remove-nth selected (copy-tree tasks))))
                                                       "selected-task")
                                         model))))
         "delete task")))
