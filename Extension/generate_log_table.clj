(defn dB->scale [ind dB] [ind (float (Math/pow 10.0 (/ dB 10.0)))])
(defn val->dB [min-dB v] (+ (/ (* (- min-dB) v) 99.0) min-dB))
(doseq [[i v] (map-indexed dB->scale (map #(val->dB -40.0 %) (range 0 100)))] (println "\tlogTable[" i "] = " v ";"))
