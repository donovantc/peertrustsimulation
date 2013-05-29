;;direct link which stored the transaction history between these two nodes
;;directed-link-breed [connection_history_links connection_history_link]
;;connection_history_links-own [n_transactions list_satisfaction list_credibility]

globals [time total_global_transactions successful_transactions number_of_nodes number_of_malicous_nodes number_of_good_nodes collusive_transaction current_ticks]

;;peer
turtles-own [service total_transactions my_trust_value malicious list_time_of_feedback_given list_time_of_transaction list_satisfaction list_credibility list_transaction_context_factor_value list_other_peer_id]

;;standard setup procedure
to setup
  clear-all
  set-default-shape turtles "circle"
  
  ;;create peers
  create-turtles number_peers 
  ask turtles
  [
    set color green
    set size 1.2
    
    ;;set service
    set service random no_services_available
    
    ;;initialise the initial trust values
    set my_trust_value global_initial_trust_value
    
    ;;set the label for the nodes
    set label precision my_trust_value 2
    
    ;;set malicious status
    set malicious false
  ]
  
  ;;set malicious peers according to percentage
  let n_malicious round ((number_peers * malicious_peers) / 100)
  
  let malicious_peers_set n-of n_malicious turtles
  ask malicious_peers_set
  [
    set color red
    set malicious true
  ]  
  
  set successful_transactions 0
  set total_global_transactions 0
  
  set number_of_nodes number_peers
  
  ;;calculate number of malicous nodes in the network
  set number_of_malicous_nodes n_malicious
  ;;calculate number of good nodes
  set number_of_good_nodes number_of_nodes - number_of_malicous_nodes
  
  ;set default collusive transaction behaviour
  set collusive_transaction false
  
  reset-ticks
  layout
end

;;this method is execute on each clock tick
to go
  if not any? turtles [stop]
  
  set current_ticks ticks
  
  ;;testing section - to remove
;  if total_global_transactions = 2000
;  [
;    let peer1 one-of turtles
;    let peer2 one-of other turtles
;    ;;let x similarity peer1 peer2 recent_time_window
;    let y calculate-general-peer-trust-PSM-credibility peer1 recent_time_window
;    show y
;    stop
;  ]
  
  
  collaborate
  clear-output
  
  if total_global_transactions > 0
  [
    let percent_successful precision ((successful_transactions / total_global_transactions) * 100) 2
    output-print word (word successful_transactions " (") (word percent_successful "%)")
  ]
  
  layout
  
  ;;remove a random peer
  remove-random-peer
  ;;add a random peer
  add-random-peer
  
  ;;resize-nodes
  tick
end

;;this method adds a new peer to the network
to add
  crt 1
  [
    set size 1.2
    
    ;;set service
    set service random no_services_available
    
    ;;initialise the initial trust values
    set my_trust_value new_initial_trust
    
    ;;set the label for the nodes
    set label precision my_trust_value 2
    
    ;;set malicious status
    set malicious new_malicious
    
    ifelse malicious
    [
      set color red
      set number_of_malicous_nodes number_of_malicous_nodes + 1
    ]
    [
      set color green
      set number_of_good_nodes number_of_good_nodes + 1
    ]
  ]
  
  set number_of_nodes number_of_nodes + 1
end

;;this method removes a random peer from the network
to remove-random-peer
  if random 100 <= rate_of_peer_removal AND rate_of_peer_removal > 0
  [
    ask one-of turtles
    [
      ask my-links
      [
        die
      ]
      
      show word "turtle removed " who
      
      ifelse malicious
      [
        set number_of_malicous_nodes number_of_malicous_nodes - 1
      ]
      [
        set number_of_good_nodes number_of_good_nodes - 1
      ]
      
      die
    ]
    set number_of_nodes number_of_nodes - 1
  ]
end

;;this method adds a random peer from the network
to add-random-peer
  if random 100 <= rate_of_random_peer_adding AND rate_of_random_peer_adding > 0
  [
    crt 1
    [
      
      set size 1.2
    
      ;;set service
      set service random no_services_available
      
      ;;initialise the initial trust values
      set my_trust_value random-float 1
      
      ;;set the label for the nodes
      set label precision my_trust_value 2
      
      ifelse random 100 <= 60
      [
        ;;set malicious status
        set malicious false
      ]
      [
        ;;set malicious status
        set malicious true
      ]
      
      ifelse malicious
      [
        set color red
        set number_of_malicous_nodes number_of_malicous_nodes + 1
      ]
      [
        set color green
        set number_of_good_nodes number_of_good_nodes + 1
      ]
      
      show word "turtle added " who
    ]
    
    set number_of_nodes number_of_nodes + 1
  ]
end

;;performs a single collaboration between a random peer and a peer that performs the desired service and is considered trustworthy
to collaborate
  
  ;;determine if collusive groups should form among malicious nodes
  ifelse (collusive_malicious_peers AND total_global_transactions > 0 AND number_of_malicous_nodes > 1 AND (random 101 < collusive_transaction_frequency))
  [
    let malicious_group get-malicious-collusive-group collusive_group_size
    set collusive_transaction true
    
    ;;perform collusive group transactions
    ask malicious_group
    [
        ;;evaluate current links
        evaluate-current-connections self
        
        let peer2 one-of other malicious_group
        perform-transaction self peer2
        
        ;;set my_trust_value calculate-general-peer-trust self
        set my_trust_value calculate-adaptive-trust self
        set label precision my_trust_value 2
    ]
  ]
  [
    ;;behave normally
    set collusive_transaction false
  
    let peer1 one-of turtles
    
    ;;evaluate current links
    evaluate-current-connections peer1
    
    ;;create a link to another turtle
    let random_service random no_services_available
    ;;list of other peers who render this service
    let potential_partners_list find-potential_peers-to-connect-with random_service
    
    ;;check if there are items in the list
    let peer2 0
    
    ifelse length potential_partners_list < 1
    [
      stop ;;exit the procedure
    ]
    [
      ;;select a random peer
      let list_counter 0
      ;;set peer2 item random (length potential_partners_list) potential_partners_list
      set peer2 item 0 potential_partners_list ;;set the chosen peer to the most trusted peer
      while [([who] of peer2 = [who] of peer1) AND list_counter < length potential_partners_list]
      [
        set peer2 item list_counter potential_partners_list
        set list_counter list_counter + 1
      ]
      
      ;;final check
      if [who] of peer1 = [who] of peer2
      [
        stop ;;exit the procedure
      ]
    ]
    
    ;;perform the transaction between two peers
    perform-transaction peer1 peer2
  ]
end

;;this method performs the transaction part of a collaboration
to perform-transaction [peer1 peer2]
  
  ;;get the id of origional node
  let peer1_id [who] of peer1
  ;;get the id of other node
  let peer2_id [who] of peer2
   
  ;;get the exact time of the transaction
  let time_of_transaction current_ticks
  
  ;;get the context factor of the transaction
  let transaction_context_factor get-transaction-context-factor
  
  ;;determing if any of the peers will act maliciously during this transaction
  let peer1_act_maliciously true
  let peer2_act_maliciously true
  
  ;;determine if this is a collusive transaction - if yes, skip this step
  if not collusive_transaction
  [  
    ;;check peer1  
    ifelse [malicious] of peer1 ;;this peer is malicious
    [      
      if random 101 <= malicious_transactions
      [
        set peer1_act_maliciously true;;act maliciously
      ]
    ]
    [
      set peer1_act_maliciously false
    ]  
    
    ;;check peer2
    ifelse [malicious] of peer2 ;;this peer is malicious
    [
      if random 101 <= malicious_transactions
      [
        set peer2_act_maliciously true ;;act maliciously
      ]
    ]
    [
      set peer2_act_maliciously false
    ]
  ]
        
  ;;perform actions via peer1
  ask turtle peer1_id
  [   
    ;;update origional peer (peer1) feedback history based on the feedback from peer2
    if (total_transactions = 0)
    [
      initialize-turtle-lists self
    ]
     
    if (peer-provides-feedback peer2 OR collusive_transaction)
    [ 
      ;;set feedback
      set list_time_of_transaction lput time_of_transaction list_time_of_transaction
      set list_satisfaction lput get-satisfaction self peer2 peer1_act_maliciously peer2_act_maliciously list_satisfaction
      set list_credibility lput get-credibility peer2 list_credibility
      set list_other_peer_id lput peer2_id list_other_peer_id      
      set list_transaction_context_factor_value lput transaction_context_factor list_transaction_context_factor_value
      
      ;;set the time of the feedback given during this transaction
      set list_time_of_feedback_given lput time_of_transaction list_time_of_feedback_given
    ]
    set total_transactions total_transactions + 1
  
    ;;set the other peers feedback from peer1
    ask turtle peer2_id
    [
      if (total_transactions = 0)
      [
        initialize-turtle-lists self
      ]
      
      if (peer-provides-feedback peer1 OR collusive_transaction)
      [
        ;;set feedback
        set list_time_of_transaction lput time_of_transaction list_time_of_transaction
        set list_satisfaction lput get-satisfaction self peer1 peer2_act_maliciously peer1_act_maliciously list_satisfaction
        set list_credibility lput get-credibility peer1 list_credibility
        set list_other_peer_id lput peer1_id list_other_peer_id      
        set list_transaction_context_factor_value lput transaction_context_factor list_transaction_context_factor_value
        
        ;;set the time of the feedback given during this transaction
        set list_time_of_feedback_given lput time_of_transaction list_time_of_feedback_given
      ]
      set total_transactions total_transactions + 1
    ]
    
    ;;create a link for this collaboration if it doesn't exist
    if not link-neighbor? peer2
    [
      create-link-with peer2
    ]
  ]
    
  ;;determine if the transaction was successful
  if not peer1_act_maliciously AND not peer2_act_maliciously
  [
    set successful_transactions successful_transactions + 1
  ]
  
  ;;update the global number of transactions
  set total_global_transactions total_global_transactions + 1
end

;;this method initialises the lists for turtles
to initialize-turtle-lists [peer]
  ;;initialise feedback lists
  set list_satisfaction []
  set list_credibility []
  set list_other_peer_id []
  set list_time_of_transaction []
  set list_transaction_context_factor_value []
  set list_time_of_feedback_given []
end

;;finding peers who offer the desired service
;;returns a list of the top [no_peers_to_return] peers
to-report find-potential_peers-to-connect-with [required-service]
  let potential_peers other turtles with [service = required-service] 

  ;;determine the trust for each peer in the list
  ask potential_peers
  [      
    ;;set my_trust_value calculate-general-peer-trust self
    set my_trust_value calculate-adaptive-trust self
    set label precision my_trust_value 2
  ]
  
  let sorted_list 0
  ;;return number of peers
  ifelse count potential_peers >= no_peers_to_return ;;list is small than number that needs to be returned
  [
    ;;sort the list and return only the first [no_peers_to_return]
    set sorted_list sublist ( sort-on [( - my_trust_value)] potential_peers ) 0 no_peers_to_return
  ]
  [
    ;;sort the entire list
    set sorted_list sort-on [(- my_trust_value)] potential_peers
  ]

  report sorted_list
end



;;returns the feedback for a collaboration
;;peer2 will give feedback for peer1's actions
to-report get-binary-satisfaction [peer1 peer2 peer1_acts_malicious peer2_acts_malicious]
  
  ;;calculate performance
  let performance_quality 0
  ;;peer1 performs the service
  ifelse peer1_acts_malicious
  [
    set performance_quality 0
  ]
  [
    ;;performance of a good node
    ;;ifelse random 100 < 80 ;;20% chance of maybe performing badly
    ;;[
      set performance_quality 1
    ;;]
    ;;[
    ;;  set performance_quality 0
    ;;]
  ]
   
  ;;calculate satisfaction    
  let satisfaction 0
  ;;peer2 provides feedback on the service
  ifelse peer2_acts_malicious
  [
      ;;dont collaborate
      ifelse performance_quality = 0
      [
        set satisfaction 1
      ]
      [
        set satisfaction 0
      ]
   ]
   [
     ;;dont act maliciously
      set satisfaction performance_quality
   ]
    
 report satisfaction
end


;;returns the feedback for a collaboration
;;peer2 will give feedback for peer1's actions
to-report get-satisfaction [peer1 peer2 peer1_acts_malicious peer2_acts_malicious]
  
  ;;check if this is a collusive transaction
  if collusive_transaction
  [
    ;;return a good rating
    report 0.5 + random-float 0.5
  ]
  
  ;;not a collusive transaction - therefore behave normally
    
  ;;calculate performance
  let performance_quality 0
  ;;peer1 performs the service
  ifelse peer1_acts_malicious
  [
    set performance_quality random 4 ;;between 0 and 3
  ]
  [
    ;;performance of a good node
    ifelse random 100 < 80 ;;20% chance of maybe performing badly
    [
      set performance_quality 5 + random 6 ;;between 5 and 10
    ]
    [
      set performance_quality 3 + random 8 ;;between 3 and 10
    ]
  ]
   
  ;;calculate satisfaction    
  let satisfaction 0.0
  ;;peer2 provides feedback on the service
  ifelse peer2_acts_malicious
  [
    ;;dont collaborate
    ifelse performance_quality <= 5
    [
      set satisfaction (performance_quality - (random (performance_quality + 1))) / 10 ;;satisfaction is anywhere between 0 and the performance quality
      if performance_quality < 0
      [
        set performance_quality 0
      ]
    ]
    [
      ;;performance is greater than 5 so only rate between 0 and 5
      set satisfaction (random 6) / 10
    ]
  ]
  [
    ;;collaborate - same as good node
    ifelse random 2 = 1 AND performance_quality < 10 ;;add or subtract
    [
      set satisfaction (performance_quality + random 2) / 10 ;;adds 0 or 1 to the performance_quality
    ]
    [
      set satisfaction (performance_quality - random 2) / 10 ;;subtracts 0 or 1 from the performance_quality
    ]
  ]
   
  report satisfaction
end

;;this method returns the transaction context factor for a particular transaction
to-report get-transaction-context-factor
  ifelse transaction_context_factor?
  [
     report random-float 1.0
  ]
  [
    report 1    
  ]
end

;;determines the credibility of a peer
;;returns a normalised credibility value
to-report get-credibility [peer]  
  report random-float 1.0
end

;;evaluates all the connections of a peer
;;the link is removed if the nodes trust value is below the threshold
to evaluate-current-connections [peer]
  ask peer
  [
    ask my-links
    [
      if [my_trust_value] of other-end < trust_threshold
      [
        die
      ]
    ]    
  ]
end

;;this method determines if a peer should provide feedback or not
;;returns a boolean with a yes or no
to-report peer-provides-feedback [peer]
  let result true
  
  ifelse (community_context_factor?)
  [
    ask peer
    [
      ifelse malicious AND random (100) < 40
      [
        set result false
      ]
      [
        set result true
      ] 
    ]
  ]
  [
    set result true
  ]
  
  report result
end

;;this method forms collusive groups among a number of malicious peers and gives good ratings
to-report get-malicious-collusive-group [group_size_percentage]
  let group_size round ((group_size_percentage / 100 )  * number_of_malicous_nodes)
  let group_list n-of group_size turtles with [ malicious = true ]
  
  report group_list
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                     GENERAL PEER TRUST CALCULATION (BASIC)    - UPDATE IF USING THIS                               ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;this method calculates the trust of a peer according to the peerTrust algorithm using the PeerTrust TVM metric
;;this method assumes that the transaction history for this peer is stored at this peer
;;the out-links store all the transaction information as given to a particular node
to-report calculate-general-peer-trust [peer]
  let total_trust 0.0
  
  ask peer
  [    
    let counter 0
    
    ifelse total_transactions > 0
    [
      foreach list_satisfaction ;;all transactions with this neighbour
      [
        let temp_credibility (item counter list_credibility)
        let temp_transaction_context_factor (item counter list_transaction_context_factor_value)
        let transaction_total precision (? * temp_credibility * temp_transaction_context_factor) 3
        
        ;;add to total sum for trust
        set total_trust (total_trust + transaction_total)
        
        set counter counter + 1
      ]
    ]
    [
      set total_trust my_trust_value 
    ]
  ]
  
  ;;normalise the trust value
  ;;set total_trust total_trust
  
  show total_trust
    
  report total_trust
end

;;this is a utility function to square a number x
to-report square [x]
  report x * x
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                    CREDIBILITY PEER TRUST CALCULATION (BASIC)                                                      ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;this method calculates the trust for a peer, taking into account the adaptive trust calculation
to-report calculate-adaptive-trust [peer]
  let recent_trust 0
  let adaptive_trust 0
  
  ifelse psm_credibility;; AND [total_transactions] of peer > 100
  [
    set recent_trust calculate-general-peer-trust-PSM-credibility peer recent_time_window
    set adaptive_trust calculate-general-peer-trust-PSM-credibility peer adaptive_time_window
  ]
  [
    set recent_trust calculate-general-peer-trust-TVM-credibility peer recent_time_window
    set adaptive_trust calculate-general-peer-trust-TVM-credibility peer adaptive_time_window
  ]
  
  ifelse (recent_trust - adaptive_trust) > time_threshold
  [
    report adaptive_trust
  ]
  [
    report recent_trust
  ] 
  
end

;this method calculates the community context factor within a particular time windows
to-report calculate-community-context-factor [peer time_ticks]
  let number_times_given_feedback 0
  let transactions_in_time_window 0
  
  ask peer
  [
    if total_transactions > 0
    [
      ;get number of transactions where feedback is provided in the given time window
      foreach list_time_of_feedback_given
      [
        if (time_ticks > current_ticks OR ? >= (current_ticks - time_ticks))
        [
          set number_times_given_feedback number_times_given_feedback + 1
        ]
      ]
      
      ;get total number of transactions in a provide time window
      foreach list_time_of_transaction
      [
        if (time_ticks > current_ticks OR ? >= (current_ticks - time_ticks))
        [
          set transactions_in_time_window transactions_in_time_window + 1
        ]
      ]
    ]
  ]
  
  report number_times_given_feedback / transactions_in_time_window
end


;;this method calculates the total credibility (trust values) for all a peers transactions
;;this method takes into account the time of the transactions - using global variables recent_time_window and adaptive_time_window passed as parameters
to-report calculate-total-trust-values-for-TVM-credibility [peer time_ticks]
let total_trust 0.0

ask peer
[
 if total_transactions > 0
 [
   let counter 0  ;;to get the time of the transaction
   foreach list_other_peer_id
   [
     ;;get the time of the transaction
     let transaction_time item counter list_time_of_transaction
     
     if (time_ticks > current_ticks OR transaction_time >= (current_ticks - time_ticks)) AND not (turtle ? = NOBODY)
     [
       ask turtle ?
       [
         set total_trust total_trust + my_trust_value
       ]
     ]
     
     set counter counter + 1
   ]
 ]
]

report total_trust
end

;;this method calculates the trust of a peer according to the peerTrust algorithm
;;this method assumes that the transaction history for this peer is stored at this peer
;;the out-links store all the transaction information as given to a particular node
;;this method takes into account the time of the transactions - using global variables recent_time_window and adaptive_time_window passed as parameters
to-report calculate-general-peer-trust-TVM-credibility [peer time_ticks]
  let total_trust 0.0
  
  ask peer
  [    
    let counter 0
    
    ifelse total_transactions > 0
    [
      ;;get the sum of the trust value of other peers for all transactions in a given time window. Used to normalise credibility
      let sum_other_peers_trust_values calculate-total-trust-values-for-TVM-credibility self time_ticks
      
    
      ifelse not (sum_other_peers_trust_values = 0)
      [
        ;;get the community context factor
        let temp_community_context_factor 1
        if community_context_factor?
        [
          set temp_community_context_factor calculate-community-context-factor self time_ticks
        ]
        
        foreach list_satisfaction ;;all transactions with this neighbour
        [
          ;;check if this transaction is in the given time window
          let transaction_time item counter list_time_of_transaction
          if time_ticks > current_ticks OR transaction_time >= (current_ticks - time_ticks) ;;only consider this transaction if it is in the time interval
          [
            let temp_id (item counter list_other_peer_id)
            
            if not (turtle temp_id = NOBODY) ;;this turtle still exists
            [
              let temp_credibility 0.0
              
              ask turtle temp_id
              [
                set temp_credibility my_trust_value
              ]
              
              ;;get transaction context factor
              let temp_transaction_context_factor (item counter list_transaction_context_factor_value)
              
              let transaction_total precision (alpha *(? * (temp_credibility / sum_other_peers_trust_values) * temp_transaction_context_factor)) 3
              
              ;;add to total sum for trust
              set total_trust (total_trust + transaction_total)
            ]
          ]
          
          set counter counter + 1
        ]
        
        set total_trust total_trust + (beta * temp_community_context_factor)
      ]
      [ ;;trust not calculated because sum of other peers is zero
        set total_trust my_trust_value
      ]
    ]
    [ ;;no transactions so trust is not calculated
      set total_trust my_trust_value 
    ]
  ]

  ;;remove negatives
  if total_trust < 0 [set total_trust 0]
     
  report total_trust
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                    CREDIBILITY PEER TRUST CALCULATION (Similarity)                                                 ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;this method gets the ids of the common peers the two peers (paramaters have interacted with) during a specified time window
to-report get-common-transaction-peers [peer1 peer2 time_ticks]
  let counter 0
  let list_peer1_transaction_peer_ids []
  let list_peer1_transaction_satisfaction []
  let list_peer2_transaction_peer_ids []
  let list_common_transaction_peer_ids []

  ;;get ids of other peers transacted with during this time interval
  ask peer1
  [
    if length list_time_of_transaction > 0
    [
      foreach list_time_of_transaction
      [
        if (time_ticks > current_ticks OR ? >= (current_ticks - time_ticks))
        [
          set list_peer1_transaction_peer_ids lput (item counter list_other_peer_id) list_peer1_transaction_peer_ids
        ]
        
        set counter counter + 1
      ]
    ]
  ]
   
  ;remove duplicates
  set list_peer1_transaction_peer_ids remove-duplicates list_peer1_transaction_peer_ids
  
  ;;show (word "peer1 transaction times" [list_time_of_transaction] of peer1)
  ;;show (word "peer1 all transactions " [list_other_peer_id] of peer1)
  ;;show (word "peer1 " list_peer1_transaction_peer_ids)

  ;;get ids of other peers transacted with during this time interval
  set counter 0
  ask peer2
  [
    if length list_time_of_transaction > 0
    [
      foreach list_time_of_transaction
      [
        if (time_ticks > current_ticks OR ? >= (current_ticks - time_ticks))
        [
          set list_peer2_transaction_peer_ids lput (item counter list_other_peer_id) list_peer2_transaction_peer_ids
        ]        
        set counter counter + 1
      ]
    ]
  ]
  ;;remove duplicates
  set list_peer2_transaction_peer_ids remove-duplicates list_peer2_transaction_peer_ids
  
  ;;show (word "peer2 transaction times" [list_time_of_transaction] of peer2)
  ;;show (word "peer2 all transactions " [list_other_peer_id] of peer2)
  ;;show (word "peer2 " list_peer2_transaction_peer_ids)
  
  if (length list_peer1_transaction_peer_ids > 0 AND length list_peer2_transaction_peer_ids > 0)
  [
    ;;determine common peers
    foreach list_peer1_transaction_peer_ids
    [
      let temp_id ?
      foreach list_peer2_transaction_peer_ids
      [
        if temp_id = ?
        [
          set list_common_transaction_peer_ids lput ? list_common_transaction_peer_ids
        ]
      ]
    ]   
    
    ;;remove duplicates
    ;;set list_common_transaction_peer_ids remove-duplicates list_common_transaction_peer_ids
    
  ]
  
 ;; show (word "common " list_common_transaction_peer_ids)
  
  report list_common_transaction_peer_ids
end

;;this method determines the similarity between two peers
;;similarity is determed by the feedback ratings provided to peers that have interacted with both peers
to-report similarity [peer1 peer2 time_ticks]
  let common_list get-common-transaction-peers peer1 peer2 time_ticks
  let default_similarity 0.5
  let no_feedback_provided false
  
  ;;check if the common list is empty
  if length common_list = 0
  [
    report default_similarity
  ]
  
  ;;variables
  let list_peer1_satisfaction_ratings []
  let list_peer2_satisfaction_ratings []
  
  ;;get the ids of the two peers
  let peer1_id [who] of peer1
  let peer2_id [who] of peer2
  
  ;;show (word "peer1 id " peer1_id)
  ;;show (word "peer2 id " peer2_id)
  
  let numerator_total 0
  let denominator 0
  
  foreach common_list
  [
    if not (turtle ? = nobody)
    [
      ask turtle ?
      [
        let counter 0
        let peer1_total_transactions 0
        let peer1_satisfaction_total 0
        let peer2_total_transactions 0
        let peer2_satisfaction_total 0
        
        ;;show (word "other node transaction times" list_time_of_transaction)
        
        
        ;;to remove
        let list_valid_transactions []
        
        foreach list_time_of_transaction ;;check if transaction is in the time window
        [
          if (time_ticks > current_ticks OR ? >= (current_ticks - time_ticks))
          [            
            let other_peer_id item counter list_other_peer_id
            
            ;;to remove
            set list_valid_transactions lput other_peer_id list_valid_transactions
            
            ;;show (word "other_id " other_peer_id)
            if (other_peer_id = peer1_id)
            [
              set peer1_total_transactions peer1_total_transactions + 1
              set peer1_satisfaction_total peer1_satisfaction_total + item counter list_satisfaction
              ;;set list_peer1_satisfaction_ratings lput item counter list_satisfaction list_peer1_satisfaction_ratings ;;save satisfaction rating
            ]
            
            if (other_peer_id = peer2_id)
            [
              set peer2_total_transactions peer2_total_transactions + 1
              set peer2_satisfaction_total peer2_satisfaction_total + item counter list_satisfaction
              ;;set list_peer2_satisfaction_ratings lput item counter list_satisfaction list_peer2_satisfaction_ratings ;;save satisfaction rating
            ]
          ]
          set counter counter + 1
        ]
        
        ;;check if this peer provided any feedback
        ifelse not(peer1_total_transactions = 0 OR peer2_total_transactions = 0)
        [        
          ;;calculate difference for the transactions with this peer      
          let square_of_difference square ((peer1_satisfaction_total / peer1_total_transactions) - (peer2_satisfaction_total / peer2_total_transactions))
          set numerator_total numerator_total + square_of_difference
          ;;set denominator denominator + abs (peer1_satisfaction_total + peer2_satisfaction_total)
        ]
        [
          set no_feedback_provided true
        ]
      ]
    ]
  ]
  
  ;;show (word "numerator " numerator_total)
  ;;show (word "denominator " denominator)
  set denominator length common_list
  
  ;;check if any feedback is provided (numerator_total of 0 and denominator of 1 and it failed a provide feedback check = no feedback)
  if (numerator_total = 0 AND denominator = 1 AND no_feedback_provided)
  [
    report default_similarity
  ]
    
  let calculated_similarity (1 - sqrt (numerator_total / denominator))
  
  ;;show (word "similarity " calculated_similarity) 
  
  report calculated_similarity
end

;;this method calculates the total credibility (personalized similarity) for all a peers transactions
;;this method takes into account the time of the transactions - using global variables recent_time_window and adaptive_time_window passed as parameters
to-report calculate-total-trust-values-for-PSM-credibility [peer time_ticks]
  let total_similarity 0.0
  
  ask peer
  [
    if total_transactions > 0
    [
      let counter 0  ;;to get the time of the transaction
      foreach list_other_peer_id
      [
        ;;get the time of the transaction
        let transaction_time item counter list_time_of_transaction
        
        if (time_ticks > current_ticks OR transaction_time >= (current_ticks - time_ticks)) AND not (turtle ? = NOBODY)
        [
          ask turtle ?
          [
            set total_similarity total_similarity + similarity peer self time_ticks
          ]
        ]
        
        set counter counter + 1
      ]
    ]
  ]
  
  ;;show (word "total_similarity " total_similarity)
  report total_similarity
end

;;this method calculates the trust of a peer according to the peerTrust algorithm
;;this method assumes that the transaction history for this peer is stored at this peer
;;the out-links store all the transaction information as given to a particular node
;;this method takes into account the time of the transactions - using global variables recent_time_window and adaptive_time_window passed as parameters
to-report calculate-general-peer-trust-PSM-credibility [peer time_ticks]
  let total_trust 0.0
  
  ask peer
  [    
    let counter 0
    
    ifelse total_transactions > 0
    [
      ;;get the sum of the trust value of other peers for all transactions in a given time window. Used to normalise credibility
      let sum_other_peers_similarity calculate-total-trust-values-for-TVM-credibility self time_ticks
      
    
      ifelse not (sum_other_peers_similarity = 0)
      [
        ;;get the community context factor
        let temp_community_context_factor 1
        if community_context_factor?
        [
          set temp_community_context_factor calculate-community-context-factor self time_ticks
        ]
        
        foreach list_satisfaction ;;all transactions with this neighbour
        [
          ;;check if this transaction is in the given time window
          let transaction_time item counter list_time_of_transaction
          if time_ticks > current_ticks OR transaction_time >= (current_ticks - time_ticks) ;;only consider this transaction if it is in the time interval
          [
            let temp_id (item counter list_other_peer_id)
            
            if not (turtle temp_id = NOBODY) ;;this turtle still exists
            [
              let temp_credibility 0.0
              
              ask turtle temp_id
              [
                set temp_credibility similarity peer self time_ticks
              ]
              
              ;;get transaction context factor
              let temp_transaction_context_factor (item counter list_transaction_context_factor_value)
              
              let transaction_total precision (alpha * (? * (temp_credibility / sum_other_peers_similarity) * temp_transaction_context_factor)) 3
              
              ;;add to total sum for trust
              set total_trust (total_trust + transaction_total)
            ]
          ]
          
          set counter counter + 1
        ]
        
        set total_trust total_trust + (beta * temp_community_context_factor)
      ]
      [ ;;trust not calculated because sum of other peers is zero
        set total_trust my_trust_value 
      ]
    ]
    [ ;;no transactions so trust is not calculated
      set total_trust my_trust_value 
    ]
  ]

  ;;remove negatives
  if total_trust < 0 [set total_trust 0]
     
  ;;show (word "total trust " total_trust)
  report total_trust
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;         PLOT        ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;this methods plots the points representing the trust computation error rate against the percentage of malicious peers
;;the parameter computation_type takes 0 for conventional or 1 for trust computation error rate
to trust-computation-error [computation_type]
  let error_rate 0
  
  ifelse computation_type = 0
  [
    set error_rate sum ([square my_trust_value] of turtles)
  ]
  [
    ask turtles
    [
      ifelse malicious
      [
        set error_rate error_rate + (1 - (malicious_transactions / 100))
      ]
      [
        set error_rate error_rate + 1
      ]
    ] 
  ]
  
  set error_rate error_rate / count turtles
  ;;show word "trust computation error " precision (sqrt error_rate) 3
  ;;set trust_computation_error sqrt error_rate 
  ;;set percentage_of_malicious_peers malicious_peers
end

;;;;;;;;;;
;;layout;;
;;;;;;;;;;

to fix-layout
  resize-nodes
  layout
end

;; resize-nodes, change back and forth from size based on degree to a size of 1
to resize-nodes
  ifelse all? turtles [size <= 1]
  [
    ;; a node is a circle with diameter determined by
    ;; the SIZE variable; using SQRT makes the circle's
    ;; area proportional to its degree
    ask turtles [ set size 0.5 + (sqrt my_trust_value)] ;;sqrt reputation]
  ]
  [
    ask turtles [ set size 1 ]
  ]
end

to layout
  ;; the number 3 here is arbitrary; more repetitions slows down the
  ;; model, but too few gives poor layouts
  repeat 3 [
    ;; the more turtles we have to fit into the same amount of space,
    ;; the smaller the inputs to layout-spring we'll need to use
    let factor sqrt count turtles
    ;; numbers here are arbitrarily chosen for pleasing appearance
    layout-spring turtles links (1 / factor) (7 / factor) (10 / factor)
    display  ;; for smooth animation
  ]
  ;; don't bump the edges of the world
  let x-offset max [xcor] of turtles + min [xcor] of turtles
  let y-offset max [ycor] of turtles + min [ycor] of turtles
  ;; big jumps look funny, so only adjust a little each time
  set x-offset limit-magnitude x-offset 0.1
  set y-offset limit-magnitude y-offset 0.1
  ask turtles [ setxy (xcor - x-offset / 2) (ycor - y-offset / 2) ]
end

to-report limit-magnitude [number limit]
  if number > limit [ report limit ]
  if number < (- limit) [ report (- limit) ]
  report number
end
@#$#@#$#@
GRAPHICS-WINDOW
632
10
1255
567
35
30
8.634
1
10
1
1
1
0
0
0
1
-35
35
-30
30
0
0
1
ticks
30.0

BUTTON
549
10
616
43
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
6
27
178
60
number_peers
number_peers
0
100
100
1
1
NIL
HORIZONTAL

BUTTON
548
53
616
87
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
6
75
178
108
no_peers_to_return
no_peers_to_return
0
10
3
1
1
NIL
HORIZONTAL

SLIDER
6
122
178
155
no_services_available
no_services_available
0
10
6
1
1
NIL
HORIZONTAL

INPUTBOX
246
267
386
327
global_initial_trust_value
0.5
1
0
Number

INPUTBOX
246
338
387
398
trust_threshold
0.5
1
0
Number

PLOT
1273
10
1473
160
trust value
time
ave_trust_value
0.0
10.0
0.0
1.0
true
false
"if count turtles > 0\n[\nlet total_trust sum [my_trust_value] of turtles\n\nplot total_trust / count turtles\n]" "if count turtles > 0\n[\nlet total_trust sum [my_trust_value] of turtles\n\nplot total_trust / count turtles\n]"
PENS
"pen-0" 1.0 0 -7500403 true "" "if count turtles > 0\n[\nplot mean [my_trust_value] of turtles\n]"

SLIDER
5
170
177
203
malicious_peers
malicious_peers
0
100
30
1
1
%
HORIZONTAL

SLIDER
4
215
178
248
malicious_transactions
malicious_transactions
0
100
100
1
1
%
HORIZONTAL

SWITCH
4
257
180
290
collusive_malicious_peers
collusive_malicious_peers
1
1
-1000

OUTPUT
1274
186
1411
233
12

TEXTBOX
1283
170
1433
188
Successful Transactions
11
0.0
1

SLIDER
1
414
199
447
recent_time_window
recent_time_window
0
500
202
1
1
ticks
HORIZONTAL

SLIDER
2
454
179
487
adaptive_time_window
adaptive_time_window
0
100
30
1
1
NIL
HORIZONTAL

INPUTBOX
247
408
388
468
time_threshold
0.2
1
0
Number

TEXTBOX
30
585
167
623
---------------------------\nManually Add New Peer\n---------------------------
11
0.0
1

SWITCH
12
631
145
664
new_malicious
new_malicious
1
1
-1000

INPUTBOX
12
676
145
736
new_initial_trust
0.8
1
0
Number

BUTTON
39
745
102
778
Add
add
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1278
272
1387
317
Number of Nodes
number_of_nodes
2
1
11

SLIDER
3
498
180
531
rate_of_peer_removal
rate_of_peer_removal
0
100
0
1
1
%
HORIZONTAL

SLIDER
4
541
210
574
rate_of_random_peer_adding
rate_of_random_peer_adding
0
100
0
1
1
%
HORIZONTAL

SWITCH
196
28
387
61
transaction_context_factor?
transaction_context_factor?
1
1
-1000

SWITCH
197
73
389
106
community_context_factor?
community_context_factor?
0
1
-1000

MONITOR
1278
327
1388
372
Malicious Nodes
number_of_malicous_nodes
0
1
11

MONITOR
1278
380
1389
425
Good Nodes
number_of_good_nodes
0
1
11

SLIDER
3
298
217
331
collusive_transaction_frequency
collusive_transaction_frequency
0
100
30
1
1
%
HORIZONTAL

SLIDER
2
336
218
369
collusive_group_size
collusive_group_size
0
100
20
1
1
%
HORIZONTAL

SWITCH
196
117
332
150
psm_credibility
psm_credibility
0
1
-1000

INPUTBOX
246
472
389
532
alpha
0.8
1
0
Number

INPUTBOX
245
536
390
596
beta
0.2
1
0
Number

BUTTON
537
95
626
128
Fix Layout
fix-layout
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -7500403 true true 135 285 195 285 270 90 30 90 105 285
Polygon -7500403 true true 270 90 225 15 180 90
Polygon -7500403 true true 30 90 75 15 120 90
Circle -1 true false 183 138 24
Circle -1 true false 93 138 24

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
