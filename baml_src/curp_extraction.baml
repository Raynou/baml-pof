class PdfCURPInformation {
    Names: string[] @description("Los nombres que tiene una persona, en México no existe limite legal de cuantos nombres puede tener una persona, entonces se define como un arreglo."),
    FirstLastName: string @description("Apellido paterno de la persona"),
    SecondLastName: string @description("Apellido materno de la persona. Obligatorio en México"),
    CURP: string @description("Clave alfanumérica de 18 caracteres que representa la clave de registro única de la persona"),
    RegistrationDate: string @description("Fecha en la que se dió de alta la persona en el registro poblacional"),
    RegistrationState: string @description("Entidad federativa de registro (\"Entidad de registro\"), p. ej. JALISCO"),
    Folio: string @description("Folio de la constancia, tal como aparece en el documento. Es un identificador, no un número de página"),
    BarCode: int @description("Código de barras que contiene codificado el número de identificación del documento probatorio de identidad")
}

class MissingInformation {
    Kind: "missing_information",
    Reason: string @description("El documento es un CURP, pero le falta información. Explica cual")
}

class NotACURP {
    Kind: "not_a_curp",
    Reason: string @description("Por que el documento no es una constancia CURP"),
}

/*
* Extract informacion from CURP
*/
// `document` es el texto extraído de un PDF o una imagen.
function ExtractCurpInformationV1(document: string | image) -> PdfCURPInformation | MissingInformation | NotACURP {
    client: if (env.CLIENT.or("local") == "local") { LocalClient() } else { OpenAI }
    prompt: `
        ${role("system")}
        Extraes datos de una Constancia de la Clave Única de Registro de Población (CURP) de México.
        El documento es una imagen o el texto extraído de un PDF. El texto extraído pierde el diseño: etiquetas como
        "Nombre" o "Clave:" pueden aparecer lejos de sus valores.

        Reglas:
        - Copia cada valor exactamente como aparece en el documento. No inventes datos.
        - El documento contiene DOS nombres de personas: el del funcionario que firma (aparece junto a su cargo,
          p. ej. "SECRETARIA DE GOBERNACIÓN") y el del titular de la CURP. Extrae SOLO el del titular; ignora al funcionario.
        - El nombre del titular aparece en una sola línea, cerca de la CURP, en este orden: NOMBRE(S), APELLIDO PATERNO, APELLIDO MATERNO.
          Ejemplo: "JUAN CARLOS PEREZ LOPEZ" -> Names: ["JUAN", "CARLOS"], FirstLastName: "PEREZ", SecondLastName: "LOPEZ".
        - Los nombres y apellidos nunca contienen dígitos y nunca son partes de la CURP.
        - Usa la CURP para identificar al titular y comprobar la separación: su 1ª letra es la inicial del apellido paterno,
          su 3ª letra es la inicial del apellido materno y su 4ª letra es la inicial del primer nombre.
          Si las iniciales no coinciden, elegiste el nombre equivocado.

        Si el documento es una CURP pero le falta información, responde con el segundo esquema (Kind: "missing_information") y explica qué falta.

        Si el documento no es una CURP, responde con el tercer esquema (Kind: "not_a_curp") y explica por qué.

        Escribe siempre en español cualquier texto libre de tu respuesta (por ejemplo, Reason).

        ${ctx.output_format()}

        ${role("user")}
        ${document}
    `
}