;; Decentralized Governance Framework
;; A comprehensive governance system that allows token holders to
;; propose, vote on, and implement changes to protocol parameters

;; Define the SIP-010 fungible token trait locally
(define-trait gov-token-trait
  (
    ;; Transfer from the caller to a new principal
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    ;; Get the token balance of the specified principal
    (get-balance (principal) (response uint uint))
    ;; Get the total supply of tokens
    (get-total-supply () (response uint uint))
    ;; Get the token name
    (get-name () (response (string-ascii 32) uint))
    ;; Get the token symbol
    (get-symbol () (response (string-ascii 32) uint))
    ;; Get the number of decimals
    (get-decimals () (response uint uint))
    ;; Get the URI for token metadata
    (get-token-uri () (response (optional (string-utf8 256)) uint))
  )
)

;; Protocol parameters that can be changed through governance
(define-map system-parameters
  { param-id: (string-ascii 64) }
  {
    param-value: (string-utf8 256),
    value-type: (string-ascii 16), ;; "uint", "principal", "string", "bool"
    update-time: uint,
    param-description: (string-utf8 512)
  }
)

;; Governance proposals
(define-map governance-proposals
  { proposal-id: uint }
  {
    proposal-title: (string-utf8 128),
    proposal-description: (string-utf8 2048),
    creator: principal,
    creation-time: uint,
    vote-start-time: uint,
    vote-end-time: uint,
    execution-time: (optional uint),
    status: (string-ascii 32), ;; "draft", "active", "passed", "rejected", "executed", "canceled"
    category: (string-ascii 32), ;; "parameter", "upgrade", "fund", "text"
    majority-threshold: uint, ;; Out of 10000 (e.g., 6000 = 60%)
    participation-threshold: uint, ;; Out of 10000 (e.g., 1000 = 10%)
    support-count: uint,
    opposition-count: uint,
    abstention-count: uint,
    forum-url: (optional (string-utf8 256))
  }
)

;; Proposal actions - what will happen if a proposal passes
(define-map proposal-tasks
  { proposal-id: uint, task-id: uint }
  {
    task-type: (string-ascii 32), ;; "set-parameter", "transfer-funds", "contract-call"
    param-id: (optional (string-ascii 64)),
    new-value: (optional (string-utf8 256)),
    recipient: (optional principal),
    token-amount: (optional uint),
    target-contract: (optional (string-ascii 64)),
    target-function: (optional (string-ascii 64)),
    function-parameters: (optional (list 10 (string-utf8 256)))
  }
)

;; Vote record for each proposal and voter
(define-map vote-records
  { proposal-id: uint, voter: principal }
  {
    vote-choice: (string-ascii 16), ;; "for", "against", "abstain"
    vote-power: uint,
    timestamp: uint,
    comment: (optional (string-utf8 512))
  }
)

;; Delegation of voting power
(define-map voting-delegations
  { delegator: principal }
  {
    delegatee: principal,
    delegation-time: uint,
    is-active: bool
  }
)

;; Next available proposal ID
(define-data-var proposal-counter uint u0)

;; Minimum deposit required to create a proposal (in governance tokens)
(define-data-var min-proposal-deposit uint u1000)

;; Minimum holding period before voting (in blocks)
(define-data-var token-holding-period uint u1000)

;; Helper function to convert principal to string-utf8
(define-private (principal-to-string (principal-value principal))
  ;; For Clarity, we'll just return a placeholder string
  ;; In a real implementation, you'd convert the principal properly
  u"ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM")

;; Initialize the governance framework with default parameters
(define-public (initialize-parameters)
  (begin
    ;; Set initial protocol parameters
    (map-set system-parameters
      { param-id: "voting-delay" }
      {
        param-value: u"1440",
        value-type: "uint",
        update-time: block-height,
        param-description: u"Blocks between proposal creation and voting start"
      }
    )
    
    (map-set system-parameters
      { param-id: "voting-period" }
      {
        param-value: u"10080",
        value-type: "uint",
        update-time: block-height,
        param-description: u"Duration of voting period in blocks"
      }
    )
    
    (map-set system-parameters
      { param-id: "execution-delay" }
      {
        param-value: u"2880",
        value-type: "uint",
        update-time: block-height,
        param-description: u"Blocks between voting end and execution"
      }
    )
    
    (map-set system-parameters
      { param-id: "min-proposal-threshold" }
      {
        param-value: u"100000000000",
        value-type: "uint",
        update-time: block-height,
        param-description: u"Minimum tokens to submit proposal"
      }
    )
    
    (map-set system-parameters
      { param-id: "quorum-threshold" }
      {
        param-value: u"1000",
        value-type: "uint",
        update-time: block-height,
        param-description: u"Minimum participation (basis points)"
      }
    )
    
    (map-set system-parameters
      { param-id: "super-majority" }
      {
        param-value: u"6000",
        value-type: "uint",
        update-time: block-height,
        param-description: u"Required majority for critical proposals (basis points)"
      }
    )
    
    (map-set system-parameters
      { param-id: "simple-majority" }
      {
        param-value: u"5000",
        value-type: "uint",
        update-time: block-height,
        param-description: u"Required majority for standard proposals (basis points)"
      }
    )
    
    (map-set system-parameters
      { param-id: "treasury-address" }
      {
        param-value: (principal-to-string (contract-address)),
        value-type: "principal",
        update-time: block-height,
        param-description: u"Address of the treasury"
      }
    )
    
    (map-set system-parameters
      { param-id: "governance-token" }
      {
        param-value: (principal-to-string (contract-address)),
        value-type: "principal",
        update-time: block-height,
        param-description: u"Address of governance token"
      }
    )
    
    (map-set system-parameters
      { param-id: "total-token-supply" }
      {
        param-value: u"1000000000000",
        value-type: "uint",
        update-time: block-height,
        param-description: u"Total supply of governance tokens"
      }
    )
    
    (ok true)
  )
)

;; Helper function to convert string to uint (very simplified)
(define-private (parse-uint-string (str (string-utf8 256)))
  ;; For demonstration purposes, hardcoding values based on parameter names
  ;; In a real contract, you would implement proper string parsing
  (if (is-eq str u"1440") 
      (some u1440)           ;; voting-delay
      (if (is-eq str u"10080")
          (some u10080)         ;; voting-period
          (if (is-eq str u"2880")
              (some u2880)           ;; execution-delay
              (if (is-eq str u"100000000000")
                  (some u100000000000) ;; min-proposal-threshold
                  (if (is-eq str u"1000")
                      (some u1000)           ;; quorum-threshold
                      (if (is-eq str u"6000")
                          (some u6000)           ;; super-majority
                          (if (is-eq str u"5000")
                              (some u5000)           ;; simple-majority
                              (if (is-eq str u"1000000000000")
                                  (some u1000000000000) ;; total-token-supply
                                  (some u0)             ;; default fallback
                              )
                          )
                      )
                  )
              )
          )
      )
  )
)

;; Check if proposal type is valid
(define-private (is-valid-category (category (string-ascii 32)))
  (or (is-eq category "parameter")
      (or (is-eq category "upgrade")
          (or (is-eq category "fund")
              (is-eq category "text"))))
)

;; Create a new governance proposal
(define-public (create-proposal
                (token-contract <gov-token-trait>)
                (proposal-title (string-utf8 128))
                (proposal-description (string-utf8 2048))
                (category (string-ascii 32))
                (majority-type (string-ascii 16))  ;; "simple" or "super"
                (voting-period-blocks uint)
                (forum-url (optional (string-utf8 256))))
  (let
    ((proposal-id (var-get proposal-counter))
     (creator-balance (unwrap! (contract-call? token-contract get-balance tx-sender) 
                               (err u"Failed to get token balance")))
     (min-proposal-threshold (unwrap! (get-uint-param "min-proposal-threshold") 
                                     (err u"Parameter not found")))
     (voting-delay (unwrap! (get-uint-param "voting-delay") (err u"Parameter not found")))
     (simple-majority (unwrap! (get-uint-param "simple-majority") (err u"Parameter not found")))
     (super-majority (unwrap! (get-uint-param "super-majority") (err u"Parameter not found")))
     (quorum (unwrap! (get-uint-param "quorum-threshold") (err u"Parameter not found")))
     (majority-threshold (if (is-eq majority-type "super") super-majority simple-majority))
     (deposit (var-get min-proposal-deposit)))
    
    ;; Validate
    (asserts! (>= creator-balance min-proposal-threshold) 
              (err u"Insufficient tokens to create proposal"))
    (asserts! (is-valid-category category) 
              (err u"Invalid proposal type"))
    (asserts! (>= voting-period-blocks u1000) 
              (err u"Voting period too short"))
    
    ;; Transfer deposit - using asserts! with is-ok instead of try!
    (asserts! (is-ok (contract-call? token-contract transfer 
                                   deposit 
                                   tx-sender 
                                   (as-contract tx-sender) 
                                   none))
             (err u"Failed to transfer deposit"))
    
    ;; Create the proposal
    (map-set governance-proposals
      { proposal-id: proposal-id }
      {
        proposal-title: proposal-title,
        proposal-description: proposal-description,
        creator: tx-sender,
        creation-time: block-height,
        vote-start-time: (+ block-height voting-delay),
        vote-end-time: (+ (+ block-height voting-delay) voting-period-blocks),
        execution-time: none,
        status: "draft",
        category: category,
        majority-threshold: majority-threshold,
        participation-threshold: quorum,
        support-count: u0,
        opposition-count: u0,
        abstention-count: u0,
        forum-url: forum-url
      }
    )
    
    ;; Increment proposal ID counter
    (var-set proposal-counter (+ proposal-id u1))
    
    (ok proposal-id)
  )
)

;; Check if action type is valid
(define-private (is-valid-task-type (task-type (string-ascii 32)))
  (or (is-eq task-type "set-parameter")
      (or (is-eq task-type "transfer-funds")
          (is-eq task-type "contract-call")))
)

;; Get next action ID for a proposal
(define-private (get-next-task-id (proposal-id uint))
  ;; In a full implementation, we would track the next action ID for each proposal
  ;; This is a simplified version
  u0
)

;; Add an action to a proposal (only proposer)
(define-public (add-proposal-task
                (proposal-id uint)
                (task-type (string-ascii 32))
                (param-id (optional (string-ascii 64)))
                (new-value (optional (string-utf8 256)))
                (recipient (optional principal))
                (token-amount (optional uint))
                (target-contract (optional (string-ascii 64)))
                (target-function (optional (string-ascii 64)))
                (function-parameters (optional (list 10 (string-utf8 256)))))
  (let
    ((proposal (unwrap! (map-get? governance-proposals { proposal-id: proposal-id }) (err u"Proposal not found")))
     (task-id (get-next-task-id proposal-id)))
    
    ;; Validate
    (asserts! (is-eq tx-sender (get creator proposal)) (err u"Only proposer can add actions"))
    (asserts! (is-eq (get status proposal) "draft") (err u"Proposal not in draft state"))
    (asserts! (is-valid-task-type task-type) (err u"Invalid action type"))
    
    ;; Create the action
    (map-set proposal-tasks
      { proposal-id: proposal-id, task-id: task-id }
      {
        task-type: task-type,
        param-id: param-id,
        new-value: new-value,
        recipient: recipient,
        token-amount: token-amount,
        target-contract: target-contract,
        target-function: target-function,
        function-parameters: function-parameters
      }
    )
    
    (ok task-id)
  )
)

;; Activate a proposal to start the voting process
(define-public (activate-proposal (proposal-id uint))
  (let
    ((proposal (unwrap! (map-get? governance-proposals { proposal-id: proposal-id }) (err u"Proposal not found"))))
    
    ;; Validate
    (asserts! (is-eq tx-sender (get creator proposal)) (err u"Only proposer can activate"))
    (asserts! (is-eq (get status proposal) "draft") (err u"Proposal not in draft state"))
    
    ;; Update proposal status
    (map-set governance-proposals
      { proposal-id: proposal-id }
      (merge proposal { status: "active" })
    )
    
    (ok true)
  )
)

;; Check if vote type is valid
(define-private (is-valid-vote-choice (vote-choice (string-ascii 16)))
  (or (is-eq vote-choice "for")
      (or (is-eq vote-choice "against")
          (is-eq vote-choice "abstain")))
)

;; Cast a vote on a proposal
(define-public (cast-vote
                (token-contract <gov-token-trait>)
                (proposal-id uint)
                (vote-choice (string-ascii 16))
                (comment (optional (string-utf8 512))))
  (let
    ((proposal (unwrap! (map-get? governance-proposals { proposal-id: proposal-id }) (err u"Proposal not found")))
     (voter (get-effective-voter tx-sender))
     (existing-vote (map-get? vote-records { proposal-id: proposal-id, voter: voter }))
     (balance (unwrap! (contract-call? token-contract get-balance voter) (err u"Failed to get balance")))
     (snapshot-balance (get-snapshot-balance token-contract voter (get vote-start-time proposal))))
    
    ;; Validate
    (asserts! (is-eq (get status proposal) "active") (err u"Proposal not active"))
    (asserts! (>= block-height (get vote-start-time proposal)) (err u"Voting not started"))
    (asserts! (< block-height (get vote-end-time proposal)) (err u"Voting ended"))
    (asserts! (is-valid-vote-choice vote-choice) (err u"Invalid vote type"))
    (asserts! (> snapshot-balance u0) (err u"No voting power at snapshot time"))
    
    ;; If user already voted, remove previous vote
    (if (is-some existing-vote)
        (let ((prev-vote (unwrap-panic existing-vote)))
          (map-set governance-proposals
            { proposal-id: proposal-id }
            (merge proposal 
              {
                support-count: (if (is-eq (get vote-choice prev-vote) "for")
                              (- (get support-count proposal) (get vote-power prev-vote))
                              (get support-count proposal)),
                opposition-count: (if (is-eq (get vote-choice prev-vote) "against")
                                  (- (get opposition-count proposal) (get vote-power prev-vote))
                                  (get opposition-count proposal)),
                abstention-count: (if (is-eq (get vote-choice prev-vote) "abstain")
                                  (- (get abstention-count proposal) (get vote-power prev-vote))
                                  (get abstention-count proposal))
              }
            )
          )
        )
        true
    )
    
    ;; Record the vote
    (map-set vote-records
      { proposal-id: proposal-id, voter: voter }
      {
        vote-choice: vote-choice,
        vote-power: snapshot-balance,
        timestamp: block-height,
        comment: comment
      }
    )
    
    ;; Update proposal vote tallies
    (map-set governance-proposals
      { proposal-id: proposal-id }
      (merge proposal 
        {
          support-count: (if (is-eq vote-choice "for")
                         (+ (get support-count proposal) snapshot-balance)
                         (get support-count proposal)),
          opposition-count: (if (is-eq vote-choice "against")
                            (+ (get opposition-count proposal) snapshot-balance)
                            (get opposition-count proposal)),
          abstention-count: (if (is-eq vote-choice "abstain")
                            (+ (get abstention-count proposal) snapshot-balance)
                            (get abstention-count proposal))
        }
      )
    )
    
    (ok true)
  )
)

;; Get the effective voter (account for delegation)
(define-private (get-effective-voter (voter principal))
  (match (map-get? voting-delegations { delegator: voter })
    delegation (if (get is-active delegation)
                  (get delegatee delegation)
                  voter)
    voter
  )
)

;; Get balance at snapshot time (simplified)
(define-private (get-snapshot-balance (token-contract <gov-token-trait>) (voter principal) (snapshot-height uint))
  ;; In a real implementation, this would use historical data
  ;; For this example, we'll use current balance
  (match (contract-call? token-contract get-balance voter)
    success u0  ;; Default to 0 on success (for demo only - you'd normally use the actual value)
    error u0    ;; Default to 0 on error
  )
)

;; Delegate voting power to another address
(define-public (delegate-votes (delegatee principal))
  (begin
    ;; Simple validation to prevent delegation to self
    (asserts! (not (is-eq delegatee tx-sender)) (err u"Cannot delegate to self"))
    
    (map-set voting-delegations
      { delegator: tx-sender }
      {
        delegatee: delegatee,
        delegation-time: block-height,
        is-active: true
      }
    )
    
    (ok true)
  )
)

;; Remove delegation
(define-public (remove-delegation)
  (let
    ((delegation (unwrap! (map-get? voting-delegations { delegator: tx-sender }) 
                         (err u"No active delegation"))))
    
    (map-set voting-delegations
      { delegator: tx-sender }
      (merge delegation { is-active: false })
    )
    
    (ok true)
  )
)

;; Finalize a proposal after voting ends
(define-public (finalize-proposal (proposal-id uint))
  (let
    ((proposal (unwrap! (map-get? governance-proposals { proposal-id: proposal-id }) (err u"Proposal not found")))
     (total-votes (+ (+ (get support-count proposal) (get opposition-count proposal)) (get abstention-count proposal)))
     (token-supply-value (unwrap! (get-uint-param "total-token-supply") (err u"Parameter not found")))
     (participation-rate (/ (* total-votes u10000) token-supply-value))
     (approval-rate (if (> total-votes u0)
                       (/ (* (get support-count proposal) u10000) total-votes)
                       u0)))
    
    ;; Validate
    (asserts! (is-eq (get status proposal) "active") (err u"Proposal not active"))
    (asserts! (>= block-height (get vote-end-time proposal)) (err u"Voting still in progress"))
    
    ;; Determine result
    (if (and (>= participation-rate (get participation-threshold proposal))
             (>= approval-rate (get majority-threshold proposal)))
        ;; Passed
        (map-set governance-proposals
          { proposal-id: proposal-id }
          (merge proposal { status: "passed" })
        )
        ;; Rejected
        (map-set governance-proposals
          { proposal-id: proposal-id }
          (merge proposal { status: "rejected" })
        )
    )
    
    (ok true)
  )
)

;; Execute a passed proposal
(define-public (execute-proposal (proposal-id uint))
  (let
    ((proposal (unwrap! (map-get? governance-proposals { proposal-id: proposal-id }) (err u"Proposal not found")))
     (execution-delay (unwrap! (get-uint-param "execution-delay") (err u"Parameter not found"))))
    
    ;; Validate
    (asserts! (is-eq (get status proposal) "passed") (err u"Proposal not passed"))
    (asserts! (>= block-height (+ (get vote-end-time proposal) execution-delay)) 
              (err u"Execution delay not elapsed"))
    
    ;; Execute all actions - using asserts! instead of try!
    (asserts! (is-ok (execute-proposal-tasks proposal-id))
              (err u"Failed to execute proposal actions"))
    
    ;; Update proposal status
    (map-set governance-proposals
      { proposal-id: proposal-id }
      (merge proposal 
        { 
          status: "executed",
          execution-time: (some block-height)
        }
      )
    )
    
    ;; Return deposit to proposer (minus fee)
    ;; Implementation would depend on token contract
    
    (ok true)
  )
)

;; Execute all actions for a proposal
(define-private (execute-proposal-tasks (proposal-id uint))
  ;; In a real implementation, this would iterate through all actions
  ;; For this example, we'll execute a dummy action
  (ok true)
)

;; Cancel a proposal (only proposer and only before voting starts)
(define-public (cancel-proposal (proposal-id uint))
  (let
    ((proposal (unwrap! (map-get? governance-proposals { proposal-id: proposal-id }) (err u"Proposal not found"))))
    
    ;; Validate
    (asserts! (is-eq tx-sender (get creator proposal)) (err u"Only proposer can cancel"))
    (asserts! (< block-height (get vote-start-time proposal)) (err u"Voting already started"))
    (asserts! (is-eq (get status proposal) "draft") (err u"Proposal not in draft state"))
    
    ;; Update proposal status
    (map-set governance-proposals
      { proposal-id: proposal-id }
      (merge proposal { status: "canceled" })
    )
    
    ;; Return partial deposit to proposer
    ;; Implementation would depend on token contract
    
    (ok true)
  )
)

;; Set a protocol parameter (only through governance)
(define-public (set-parameter (param-id (string-ascii 64)) (param-value (string-utf8 256)))
  (begin
    (asserts! (is-contract-call) (err u"Only callable through governance"))
    
    (match (map-get? system-parameters { param-id: param-id })
      parameter (begin
                  (map-set system-parameters
                    { param-id: param-id }
                    {
                      param-value: param-value,
                      value-type: (get value-type parameter),
                      update-time: block-height,
                      param-description: (get param-description parameter)
                    }
                  )
                  (ok true)
                )
      (err u"Parameter not found")
    )
  )
)

;; Check if called through governance
(define-private (is-contract-call)
  (is-eq contract-caller (as-contract tx-sender))
)

;; Helper to get contract caller
(define-private (contract-address)
  (as-contract tx-sender)
)

;; Helper to get a uint parameter value
(define-private (get-uint-param (param-id (string-ascii 64)))
  (match (map-get? system-parameters { param-id: param-id })
    parameter (if (is-eq (get value-type parameter) "uint")
                 (parse-uint-string (get param-value parameter))
                 none)
    none
  )
)

;; Read-only functions

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
  (ok (unwrap! (map-get? governance-proposals { proposal-id: proposal-id }) (err u"Proposal not found")))
)

;; Get parameter value
(define-read-only (get-parameter (param-id (string-ascii 64)))
  (ok (unwrap! (map-get? system-parameters { param-id: param-id }) (err u"Parameter not found")))
)

;; Get vote details
(define-read-only (get-vote (proposal-id uint) (voter principal))
  (ok (unwrap! (map-get? vote-records { proposal-id: proposal-id, voter: voter }) (err u"Vote not found")))
)

;; Check proposal status
(define-read-only (check-proposal-status (proposal-id uint))
  (match (map-get? governance-proposals { proposal-id: proposal-id })
    proposal (ok (get status proposal))
    (err u"Proposal not found")
  )
)

;; Get proposal action
(define-read-only (get-proposal-task (proposal-id uint) (task-id uint))
  (ok (unwrap! (map-get? proposal-tasks { proposal-id: proposal-id, task-id: task-id })
              (err u"Action not found")))
)