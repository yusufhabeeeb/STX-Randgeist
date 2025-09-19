
;; STX-Randgeist
;; <add a description here>

;; Define data variables
(define-data-var entropy-accumulator (buff 32) 0x0000000000000000000000000000000000000000000000000000000000000000)
(define-data-var last-block-height uint u0)
(define-data-var nonce uint u0)

;; Error codes
(define-constant ERR_INVALID_RANGE (err u100))
(define-constant ERR_ZERO_RANGE (err u101))
(define-constant ERR_SAME_BLOCK (err u102))


;; Convert uint to buffer (simple implementation for entropy)
(define-private (uint-to-buff (value uint))
  (let
    (
      (byte-0 (mod value u256))
      (byte-1 (mod (/ value u256) u256))
      (byte-2 (mod (/ value u65536) u256))
      (byte-3 (mod (/ value u16777216) u256))
    )
    (concat 
      (concat 
        (buff-to-byte byte-0)
        (buff-to-byte byte-1))
      (concat 
        (buff-to-byte byte-2)
        (buff-to-byte byte-3)))
  )
)

;; Convert integer (0-255) to a single byte buffer
(define-private (buff-to-byte (value uint))
  (unwrap-panic (element-at 0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff value))
)

;; Combine entropy sources into a single hash
(define-private (combine-entropy (user-seed (buff 32)))
  (let 
    (
      ;; Get Stacks block header hashes (recent + previous)
      (stacks-hash (unwrap-panic (get-block-info? header-hash (- block-height u1))))
      (prev-stacks-hash (unwrap-panic (get-block-info? header-hash (- block-height u2))))
      
      ;; Current transaction data - use burn block info
      (burn-hash (unwrap-panic (get-burn-block-info? header-hash (- burn-block-height u1))))
      
      ;; Use tx-sender as an entropy source 
      (sender-bytes (unwrap-panic (to-consensus-buff? tx-sender)))
      
      ;; Current state
      (current-entropy (var-get entropy-accumulator))
      (current-nonce (var-get nonce))
      (nonce-bytes (uint-to-buff current-nonce))
      
      ;; Combine all entropy sources
      (combined-entropy (sha256 (concat 
                                  (concat stacks-hash prev-stacks-hash)
                                  (concat 
                                    (concat burn-hash sender-bytes)
                                    (concat current-entropy (sha256 nonce-bytes))))))
    )
    combined-entropy
  )
)


;; Get a byte from a buffer at specified index
(define-private (get-byte-at (buff (buff 32)) (index uint))
  (default-to 0x00 (element-at buff index))
)

;; Extract number from buffer
(define-private (extract-uint-from-buff (random-buff (buff 32)))
  (let 
    (
      (byte-0 (buff-to-uint (get-byte-at random-buff u0)))
      (byte-1 (buff-to-uint (get-byte-at random-buff u1)))
      (byte-2 (buff-to-uint (get-byte-at random-buff u2)))
      (byte-3 (buff-to-uint (get-byte-at random-buff u3)))
      (byte-4 (buff-to-uint (get-byte-at random-buff u4)))
      (byte-5 (buff-to-uint (get-byte-at random-buff u5)))
      (byte-6 (buff-to-uint (get-byte-at random-buff u6)))
      (byte-7 (buff-to-uint (get-byte-at random-buff u7)))
    )
    (+ byte-0 
      (+ (* byte-1 u256) 
        (+ (* byte-2 u65536) 
          (+ (* byte-3 u16777216) 
            (+ (* byte-4 u4294967296) 
              (+ (* byte-5 u1099511627776) 
                (+ (* byte-6 u281474976710656) 
                  (* byte-7 u72057594037927936))))))))
  )
)



;; Convert buffer byte to uint
(define-private (buff-to-uint (byte (buff 1)))
  (unwrap-panic (index-of 0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff byte))
)

;; Public functions

;; Get a random uint value between 0 and max-value (inclusive)
(define-public (get-random (user-seed (buff 32)) (max-value uint))
  (begin
    ;; Verify the range is valid
    (asserts! (> max-value u0) ERR_ZERO_RANGE)
    
    ;; Prevent same-block attacks
    (asserts! (> block-height (var-get last-block-height)) ERR_SAME_BLOCK)
    (var-set last-block-height block-height)
    
    ;; Generate raw random value
    (let 
      (
        (raw-random (combine-entropy user-seed))
        (random-uint (extract-uint-from-buff raw-random))
        (scaled-random (mod random-uint (+ max-value u1)))
      )
      
      ;; Update state for future randomness
      (var-set nonce (+ (var-get nonce) u1))
      (var-set entropy-accumulator (sha256 (concat (var-get entropy-accumulator) raw-random)))
      
      ;; Return the scaled random value
      (ok scaled-random)
    )
  )
)

;; Get a random value within a specific range (min-value to max-value, inclusive)
(define-public (get-random-in-range (user-seed (buff 32)) (min-value uint) (max-value uint))
  (begin
    ;; Verify the range is valid
    (asserts! (>= max-value min-value) ERR_INVALID_RANGE)
    
    ;; Get random value from 0 to (max-value - min-value)
    (let 
      (
        (range (- max-value min-value))
        (random-result (unwrap-panic (get-random user-seed range)))
      )
      ;; Adjust to the required range by adding min-value
      (ok (+ min-value random-result))
    )
  )
)

;; Get the current entropy accumulator state (for verification)
(define-read-only (get-entropy-state)
  (var-get entropy-accumulator)
)