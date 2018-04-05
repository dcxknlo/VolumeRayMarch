using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using System.IO;
using UnityEngine;

public enum RenderMode
{
      RawModel = 0,
      Noise = 1,
      Test = 2
}
public enum RenderNoise
{
    Pyroclastic = 0,
    Pyro2 = 1
}

[RequireComponent(typeof(Camera))]
public class VolumeRender : MonoBehaviour {

    [SerializeField] private Transform cuttingPlane;
    [SerializeField] private Mesh cubeMesh;
    [SerializeField] private Vector3 cubeWorldPos = Vector3.zero;
    [SerializeField] private Material raymarchMat;
    [SerializeField] private ComputeShader GenerateNoiseTex;

   // [SerializeField] private Vector4 lightPos;
    [SerializeField] private int texDim;
    [SerializeField] private RenderMode renderMode;
    [SerializeField] private RenderNoise noiseType;

    [SerializeField] int defaultPyroSize = 128;
    [SerializeField] int defaultRawModelSize = 256;
    [SerializeField] private bool renderRayMarch = true;
    [SerializeField] private bool evalNoiseContinuous = false;
    

    private Texture3D inputTex;
    private Camera mainCam;
    private Vector4 eyePos;
    private Vector3 cache_camPos;
    private Color32[] noiseVals;
    private Matrix4x4 objToWorld;

    private RenderTexture renderInputTex;
    const string shaderName = "VMarch";

    #region Unity Functions
    private void OnEnable()
    {
        Init();       
    }
    private void OnDisable()
    {
        if (renderInputTex)
        {
            renderInputTex.Release();
        }
    }
    private void OnRenderObject()
    {
        if (!renderRayMarch)
            return;

        if (renderMode == RenderMode.Noise && evalNoiseContinuous)
        {
            ComputeGenNoise();
        }
     
        raymarchMat.SetPass((int)renderMode);
        raymarchMat.SetInt("_FrameIndex", Time.frameCount % 8);
        //raymarchMat.SetVector("_LightPos", lightPos);
        raymarchMat.SetVector("_CuttingPos", cuttingPlane.position);
        raymarchMat.SetVector("_CuttingDir", cuttingPlane.forward);
        Graphics.DrawMeshNow(cubeMesh, cubeWorldPos, Quaternion.identity, 0);
    }
    #endregion

    #region Initialisation
    private void Init()
    {
        mainCam = this.GetComponent<Camera>();
        cache_camPos = mainCam.transform.position;
        mainCam.depthTextureMode = DepthTextureMode.Depth;

        raymarchMat = new Material(Resources.Load(shaderName) as Shader);
        if (raymarchMat == null)
        {
            Debug.Log("Shader not found");
        }

        switch (renderMode)
        {  
            case RenderMode.RawModel:
                texDim = defaultRawModelSize;
                inputTex = CreateVolume(texDim);
                InitRawModel(texDim);
                raymarchMat.SetTexture("_NoiseTex3D", inputTex);
                break;
            case RenderMode.Noise:
                texDim = defaultPyroSize;
                renderInputTex = CreateRenderVolume(texDim);
                InitNoise(texDim);
                raymarchMat.SetTexture("_NoiseTex3D", renderInputTex);
                break;
            case RenderMode.Test:
                texDim = defaultRawModelSize;
                inputTex = CreateVolume(texDim);
                InitVMarchTest(texDim);
                raymarchMat.SetTexture("_NoiseTex3D", inputTex);
                break;

        }

        raymarchMat.SetInt("_NumSamples", texDim);
        raymarchMat.SetMatrix("_ObjectToWorld", objToWorld);
        raymarchMat.SetFloat("_MinVoxelValue", 0.1f);

    }
    private void InitNoise(int dim)
    {
        ComputeGenNoise();
    }
    private void InitRawModel(int dim)
    {   
        string modelPath = @"c:\Users\SS33\Documents\Unity-Projects\VolumeRayMarch\Assets\Models\Engine256.raw";
        FileStream fs = new FileStream(modelPath, FileMode.Open);
        LoadRawFile8(ref inputTex, fs, dim);

    }
    private void InitVMarchTest(int dim)
    {
        string modelPath = @"c:\Users\SS33\Documents\Unity-Projects\VolumeRayMarch\Assets\Models\Engine256.raw";
        FileStream fs = new FileStream(modelPath, FileMode.Open);
        LoadRawFile8(ref inputTex, fs, dim);
    }

    private RenderTexture CreateRenderVolume(int dim)
    {
        RenderTexture returnTex = new RenderTexture(dim, dim, 0, RenderTextureFormat.ARGB32);
        returnTex.enableRandomWrite = true;
        returnTex.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
        returnTex.volumeDepth = dim;

        returnTex.wrapModeU = TextureWrapMode.Clamp;
        returnTex.wrapModeV = TextureWrapMode.Clamp;
        returnTex.wrapModeW = TextureWrapMode.Clamp;
        returnTex.filterMode = FilterMode.Trilinear;

        returnTex.Create();
        return returnTex;
    }
    private Texture3D CreateVolume(int dim)
    {
        Texture3D returnTex = new Texture3D(dim, dim, dim, TextureFormat.RFloat, false);

        returnTex.wrapModeU = TextureWrapMode.Clamp;
        returnTex.wrapModeV = TextureWrapMode.Clamp;
        returnTex.wrapModeW = TextureWrapMode.Clamp;
        returnTex.filterMode = FilterMode.Trilinear;

        return returnTex;
    }
    #endregion

    #region Volume Data Generation
    void ComputeGenNoise()
    {
        Graphics.SetRandomWriteTarget(0, renderInputTex);
        GenerateNoiseTex.SetTexture((int)noiseType, "InputTex", renderInputTex);
        GenerateNoiseTex.SetFloat("_FrameIndex", Time.smoothDeltaTime * 10f);
        GenerateNoiseTex.Dispatch((int)noiseType, texDim / 8, texDim / 8, texDim / 8);

    }
    private void LoadRawFile8( ref Texture3D inputTex, FileStream file, int fDim)
    {
        Color[] scalarDataBuf;
        BinaryReader bReader = new BinaryReader(file);
        byte[] buf = new byte[fDim * fDim * fDim];
        int byteSize = sizeof(byte);
        bReader.Read(buf, 0, byteSize * buf.Length);
        bReader.Close();

        scalarDataBuf = new Color[buf.Length];
        for (int i = 0; i < buf.Length; i++)
        {
            float s = (float)buf[i] / byte.MaxValue;
            scalarDataBuf[i] = new Color(s, 0, 0, 0);
        }
        inputTex.SetPixels(scalarDataBuf);
        inputTex.Apply();

        file.Close();
    }
    #endregion

    #region Helper Functions
    int WorldCoordFlatten(int dim, int x, int y, int z)
    {
        return x + dim * (y + dim * z);
    }
    private float CalcFocalLength(Camera cam)
    {
        return 1.0f / Mathf.Tan(cam.fieldOfView / 2);
    }
    private Matrix4x4 CalcModelViewMatrix(Camera cam)
    {
        return cam.worldToCameraMatrix * cam.transform.localToWorldMatrix;
    }
    private Matrix4x4 CalcModelViewMatrix(Camera cam, Transform targetObj)
    {
        return cam.worldToCameraMatrix * targetObj.localToWorldMatrix;
    }
    #endregion

}

