//
//  zxcvbn+score.swift
//  App
//
//  Created by Rémi Groult on 24/11/2019.
//

import Foundation
import zxcvbn
import czxcvbn

/*
func test() {
    let result = Zxcvbn.estimate("gsfsf").entropy
}*/
extension Zxcvbn {
    public static func estimateScore(_ password: String) -> Int{
        var info: UnsafeMutablePointer<ZxcMatch_t>?

        defer {
            ZxcvbnFreeInfo(info)
        }

        let entropy = ZxcvbnMatch(password, nil, &info)
        return crackTimeToScore(seconds: entropyToCrackTime(entropy: entropy))
    }

    //Swift port of https://github.com/dropbox/zxcvbn-ios/blob/master/Zxcvbn/DBScorer.m
    private static func entropyToCrackTime(entropy:Double) -> Double{
         /*
          threat model -- stolen hash catastrophe scenario
          assumes:
          * passwords are stored as salted hashes, different random salt per user.
             (making rainbow attacks infeasable.)
          * hashes and salts were stolen. attacker is guessing passwords at max rate.
          * attacker has several CPUs at their disposal.
          * for a hash function like bcrypt/scrypt/PBKDF2, 10ms per guess is a safe lower bound.
          * (usually a guess would take longer -- this assumes fast hardware and a small work factor.)
          * adjust for your site accordingly if you use another hash function, possibly by
          * several orders of magnitude!
          */

        let singleGuess:Double = 0.010;
        let numAttackers:Double = 100; // number of cores guessing in parallel.

        let secondsPerGuess = singleGuess / numAttackers;

        return 0.5 * pow(2, entropy) * secondsPerGuess; // average, not total
    }
    
    private static func crackTimeToScore(seconds:Double) -> Int {
        if (seconds < pow(10, 2)) {
            return 0;
        }
        if (seconds < pow(10, 4)) {
            return 1;
        }
        if (seconds < pow(10, 6)) {
            return 2;
        }
        if (seconds < pow(10, 8)) {
            return 3;
        }
        return 4;
    }
}
