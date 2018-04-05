using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class IsBehind : MonoBehaviour {

    public Transform cubeA;
    public Transform cubeB;
    public bool isBehind;
	// Update is called once per frame
	void Update () {
        if (cubeA && cubeB)
        {
           
            Vector3 aNormal = cubeA.forward;
            Vector3 ba = Vector3.Normalize((cubeA.position - cubeB.position));
            isBehind =  Vector3.Dot(ba, aNormal) < 0;
        }
    }
}
