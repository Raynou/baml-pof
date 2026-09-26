import base64
import io
import mimetypes
import sys
from pathlib import Path

from baml_bridge import BamlError
from dotenv import load_dotenv
from PIL import Image as PILImage
from pypdf import PdfReader

from baml_sdk import ExtractCurpInformationV1
from baml_sdk.baml.media import Image

# Lado mayor máximo de las imágenes. Las fotos del celular (4000x3000) tumban el encoder de visión en la GPU.
MAX_IMAGE_SIDE = 1536


def encode_image(path: Path) -> str:
    """Reduce la imagen a MAX_IMAGE_SIDE y la devuelve como JPEG en base64.

    No se corrige la orientación EXIF: el modelo ve la imagen tal como está guardada.
    """
    with PILImage.open(path) as img:
        img = img.convert("RGB")
        img.thumbnail((MAX_IMAGE_SIDE, MAX_IMAGE_SIDE))
        buf = io.BytesIO()
        img.save(buf, format="JPEG", quality=90)
    return base64.b64encode(buf.getvalue()).decode()


def load_document(path: Path) -> str | Image:
    """PDF -> su texto; imagen -> `Image` en base64 para que el modelo la vea."""
    mime, _ = mimetypes.guess_type(path)
    if mime == "application/pdf":
        return "\n".join(page.extract_text() or "" for page in PdfReader(path).pages)
    if mime and mime.startswith("image/"):
        return Image.from_base64(encode_image(path), "image/jpeg")
    raise ValueError(f"tipo de archivo no soportado: {mime}")


def main() -> None:
    load_dotenv()
    for path in map(Path, sys.argv[1:]):
        print(f"\n=== {path} ===")
        try:
            result = ExtractCurpInformationV1(document=load_document(path))
        except BamlError as e:
            print(f"{e.class_name}: {e.value}")
            continue
        print(type(result).__name__, result.model_dump_json(indent=2))
