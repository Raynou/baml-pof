# baml-pof

Prueba de concepto de [BAML](https://github.com/BoundaryML/baml) con Python. Le pasas una constancia CURP (PDF o foto) y un llm te regresa los datos ya estructurados: nombres, apellidos, CURP, folio, etc.

Si el documento no es una CURP, te dice por qué. Si le faltan datos, también te avisa.

## Qué necesitas

- [uv](https://docs.astral.sh/uv/) para Python (el proyecto usa Python 3.14, uv lo baja solo).
- El CLI de BAML, versión **0.20.1** (la toolchain nueva).
- Un modelo local o tu API Key.
> [!WARNING]  
> Carnal, no te recomiendo usar un API Key para esta PoF, porque extrae datos del CURP, si lo vas a hacer usa un modelo local o datos dummy.

## Compilar BAML

El código BAML vive en `baml_src/`, pero Python no lo lee directo. Primero hay que compilarlo:

```sh
baml generate
```

Esto lee todo `baml_src/` y genera `src/baml_sdk/`, que es el paquete de Python que importa la app (`from baml_sdk import ExtractCurpInformationV1`). Esa carpeta no está en el repo, cada quien la genera.

Si salió bien vas a ver algo así:

```
Generated python (139 file(s) → .../src/baml_sdk)
Finished generated 139 file(s) in 1s
```

**Cuándo correrlo:**

- La primera vez, después de clonar.
- Cada vez que cambies algo en `baml_src/` (un tipo, el prompt, un cliente).
- Después de un `git pull` que traiga cambios en `baml_src/`.

Si se te olvida, vas a tener un `ImportError` o la app va a usar la versión vieja de tu prompt sin avisarte.

**Otros comandos útiles:**

```sh
baml check   # solo revisa que compile, no genera nada
baml test    # corre los tests de baml_src/
```

**Si te sale un error de que falta la "agent skill"**, corre `baml agent install` o desactiva el chequeo:

```sh
export BAML_AGENT_SKILL_CHECK=off
```

## Cómo levantarlo

1. Clona el repo y entra a la carpeta.

2. Compila BAML con `baml generate`. **No te lo saltes**, sin esto Python no tiene qué importar. Los detalles están en [Compilar BAML](#compilar-baml).

3. Instala las dependencias:

   ```sh
   uv sync
   ```

4. Crea tu `.env` a partir del ejemplo:

   ```sh
   cp .env.example .env
   ```

## Cómo usarlo

Pon tus documentos en `data/` (esa carpeta está en el `.gitignore`, no se sube nada) y córrelo:

```sh
uv run baml-pof data/mi_curp.pdf data/foto.jpg
```

Le puedes pasar los archivos que quieras. Para cada uno te imprime qué tipo regresó BAML y el JSON:

- `PdfCURPInformation`: sí es una CURP y sacó todos los datos.
- `MissingInformation`: es una CURP pero le falta algo.
- `NotACURP`: no es una CURP, y te dice por qué.
- Si algo truena (el modelo respondió basura, LM Studio está apagado, etc.) te sale el error de BAML.

Los PDFs se leen como texto con `pypdf`. Las imágenes se mandan al modelo tal cual, pero antes se reducen a 1536 px por lado.

## Tests

```sh
baml test
```

No llaman al modelo. Solo revisan que el parser de BAML acomode bien las respuestas en cada tipo, así que son rápidos y no gastan nada.

## Estructura

```
baml_src/                     # código BAML, aquí es donde le mueves
  clients.baml                #   de dónde sale el modelo (LM Studio u OpenAI)
  curp_extraction.baml        #   tipos, prompt y función de extracción
  curp_extraction_tests.baml  #   tests del parser
src/baml_pof/__init__.py      # entry point: carga los archivos y llama a BAML
src/baml_sdk/                 # generado por `baml generate`, no lo edites
data/                         # tus documentos (ignorado por git)
.baml/                        # historial de llamadas (ignorado por git)
```

Cada vez que cambies algo en `baml_src/`, corre `baml generate` otra vez.
