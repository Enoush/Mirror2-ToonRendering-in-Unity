﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode()]
public class BoxBlur : MonoBehaviour
{
    public Material material;

    [Range(0,10)]
    public int BlurTime = 1;

    public float _BlurOffset = 1;

    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null)
            return;

        int width = source.width;
        int height = source.height;

        RenderTexture T1 = RenderTexture.GetTemporary(width,height);
        RenderTexture T2 = RenderTexture.GetTemporary(width, height);

        Graphics.Blit(source, T1);

        material.SetFloat("_BlurOffset", _BlurOffset);
        for (int i = 0; i < BlurTime; i++)
        {
            Graphics.Blit(T1, T2, material,1);
            Graphics.Blit(T2, T1, material,1);
        }

        Graphics.Blit(T1, destination);

        //释放资源
        RenderTexture.ReleaseTemporary(T1);
        RenderTexture.ReleaseTemporary(T2);

    }
}
