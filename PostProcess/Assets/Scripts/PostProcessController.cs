using UnityEngine;
using UnityEngine.InputSystem;

public class PostProcessController : MonoBehaviour
{
    [Header("Post Process Materials")]
    [SerializeField] private Material colorGradientMaterial;
    [SerializeField] private Material vignetteMaterial;
    [SerializeField] private Material chromaticAberrationMaterial;
    [SerializeField] private Material lensDistortionMaterial;
    [SerializeField] private Material crtLinesMaterial;
    [SerializeField] private Material pixelatedMaterial;

    [Header("Debug")]
    [SerializeField] private int currentEffect = 1;

    private void Start()
    {
        ApplyEffect(1);
    }

    private void Update()
    {
        if (Keyboard.current == null)
            return;

        if (Keyboard.current.digit1Key.wasPressedThisFrame) ApplyEffect(1);
        if (Keyboard.current.digit2Key.wasPressedThisFrame) ApplyEffect(2);
        if (Keyboard.current.digit3Key.wasPressedThisFrame) ApplyEffect(3);
        if (Keyboard.current.digit4Key.wasPressedThisFrame) ApplyEffect(4);
        if (Keyboard.current.digit5Key.wasPressedThisFrame) ApplyEffect(5);
        if (Keyboard.current.digit6Key.wasPressedThisFrame) ApplyEffect(6);
        if (Keyboard.current.digit7Key.wasPressedThisFrame) ApplyEffect(7);
    }

    private void ApplyEffect(int effectIndex)
    {
        currentEffect = effectIndex;

        DisableAllEffects();

        switch (effectIndex)
        {
            case 1:
                Debug.Log("Efecto actual: Normal");
                break;

            case 2:
                EnableMaterial(colorGradientMaterial);
                Debug.Log("Efecto actual: Color Gradient");
                break;

            case 3:
                EnableMaterial(vignetteMaterial);
                Debug.Log("Efecto actual: Vignette");
                break;

            case 4:
                EnableMaterial(chromaticAberrationMaterial);
                Debug.Log("Efecto actual: Chromatic Aberration");
                break;

            case 5:
                EnableMaterial(lensDistortionMaterial);
                Debug.Log("Efecto actual: Lens Distortion");
                break;

            case 6:
                EnableMaterial(crtLinesMaterial);
                Debug.Log("Efecto actual: CRT Lines");
                break;

            case 7:
                EnableMaterial(pixelatedMaterial);
                Debug.Log("Efecto actual: Pixelated");
                break;
        }
    }

    private void DisableAllEffects()
    {
        DisableMaterial(colorGradientMaterial);
        DisableMaterial(vignetteMaterial);
        DisableMaterial(chromaticAberrationMaterial);
        DisableMaterial(lensDistortionMaterial);
        DisableMaterial(crtLinesMaterial);
        DisableMaterial(pixelatedMaterial);
    }

    private void EnableMaterial(Material materialToEnable)
    {
        if (materialToEnable != null)
            materialToEnable.SetFloat("_Enabled", 1f);
    }

    private void DisableMaterial(Material materialToDisable)
    {
        if (materialToDisable != null)
            materialToDisable.SetFloat("_Enabled", 0f);
    }
}