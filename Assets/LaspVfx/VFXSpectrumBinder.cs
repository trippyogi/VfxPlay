using Unity.Collections;
using UnityEngine;
using UnityEngine.VFX;
using UnityEngine.VFX.Utility;

namespace Lasp.Vfx
{
    [AddComponentMenu("VFX/Property Binders/LASP/Spectrum Binder")]
    [VFXBinder("LASP/Spectrum")]
    sealed class VFXSpectrumBinder : VFXBinderBase
    {
        #region VFX Binder Implementation

        public string TextureWidthProperty {
            get => (string)_textureWidthProperty;
            set => _textureWidthProperty = value;
        }

        public string TextureProperty {
            get => (string)_textureProperty;
            set => _textureProperty = value;
        }

        [VFXPropertyBinding("System.UInt32"), SerializeField]
        ExposedProperty _textureWidthProperty = "TextureWidth";

        [VFXPropertyBinding("UnityEngine.Texture2D"), SerializeField]
        ExposedProperty _textureProperty = "WaveformTexture";

        public Lasp.AudioLevelTracker Target = null;

        public override bool IsValid(VisualEffect component)
          => Target != null &&
             component.HasUInt(_textureWidthProperty) &&
             component.HasTexture(_textureProperty);

        public override void UpdateBinding(VisualEffect component)
        {
            UpdateTexture();
            component.SetUInt(_textureWidthProperty, (uint)SpectrumWidth);
            component.SetTexture(_textureProperty, _texture);
        }

        public override string ToString()
          => $"Spectrum : '{_textureProperty}' -> {Target?.name ?? "(null)"}";

        #endregion

        #region Spectrum texture generation

        const int SpectrumWidth = 512;

        FftBuffer _fft;
        Texture2D _texture;

        void OnDestroy()
        {
            if (_texture != null)
                if (Application.isPlaying)
                    Destroy(_texture);
                else
                    DestroyImmediate(_texture);
        }

        protected override void OnDisable()
        {
            base.OnDisable();

            _fft?.Dispose();
            _fft = null;
        }

        void UpdateTexture()
        {
            if (_fft == null)
                _fft = new FftBuffer(SpectrumWidth * 2);

            if (_texture == null)
            {
                _texture =
                  new Texture2D(SpectrumWidth, 1, TextureFormat.RFloat, false) {
                    filterMode = FilterMode.Bilinear,
                    wrapMode = TextureWrapMode.Clamp
                  };
            }

            _fft.Push(Target.AudioDataSlice);
            _fft.Analyze();

            _texture.LoadRawTextureData(_fft.Spectrum);
            _texture.Apply();
        }

        #endregion
    }
}
