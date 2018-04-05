using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MeshPos : MonoBehaviour {

    // Use this for initialization
    GameObject go;

    void Start () {
         go = GameObject.CreatePrimitive(PrimitiveType.Cube);
        go.transform.position =  Vector3.one;
        Mesh mesh = go.GetComponent<MeshFilter>().sharedMesh;
        Vector3[] points = new Vector3[mesh.vertexCount];

        points = mesh.vertices;

        for (int i = 0; i < points.Length; i++)
        {
           Debug.Log(points[i]);
        }
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
