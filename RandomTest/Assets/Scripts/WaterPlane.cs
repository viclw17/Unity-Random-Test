using System.Collections;
using System.Collections.Generic;
using UnityEngine;



public class WaterPlane : MonoBehaviour
{

    public float scale = 1.0f;
    public float sinSpeedX = 1.0f;
    public float sinSpeedZ = 1.0f;
    public float perlinSpeedX = 1.0f;
    public float perlinSpeedZ = 1.0f;
    private Vector3[] baseVertices;
    public bool recalculateNormals = true;

    public bool isSin = false;
    public bool isPerlin = true;


    Mesh mesh;
    Vector3[] vertices;

    // Use this for initialization
    void Start()
    {

        mesh = GetComponent<MeshFilter>().mesh;

        if (baseVertices == null)
            baseVertices = mesh.vertices;

        vertices = new Vector3[baseVertices.Length];
    }

    // Update is called once per frame
    void Update()
    {


        for (var i = 0; i < vertices.Length; i++)
        {
            var vertex = baseVertices[i];

            if (isSin == true && isPerlin == false)
            {

                vertex.y += (Mathf.Sin(vertex.x + Time.time * sinSpeedX) * Mathf.Sin(vertex.z + Time.time * sinSpeedZ)) * scale;
            }
            if (isPerlin == true && isSin == false)
            {

                vertex.y += (Mathf.PerlinNoise(vertex.x + Time.time * perlinSpeedX, vertex.z + Time.time * perlinSpeedZ)) * scale;
            }
            if (isPerlin == true && isSin == true)
            {

                vertex.y += (Mathf.PerlinNoise(Time.time * perlinSpeedX, vertex.z + Time.time * perlinSpeedZ)) *
                    (Mathf.Sin(vertex.x + Time.time * sinSpeedX) * Mathf.Sin(vertex.z + Time.time * sinSpeedZ)) * scale;
            }

            vertices[i] = vertex;
        }

        mesh.MarkDynamic();

        mesh.vertices = vertices;

        mesh.RecalculateBounds();

        if (recalculateNormals)
            mesh.RecalculateNormals();
    }
}
