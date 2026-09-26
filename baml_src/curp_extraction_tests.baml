// Tests del parser (SAP) para ExtractCurpInformationV1: no llaman al modelo.
// Cada JSON simula una respuesta posible y verifica en qué rama de la unión cae.
// El CURP de ejemplo es el genérico para extranjeros, no uno real.

type CurpResult = PdfCURPInformation | MissingInformation | NotACURP;

test "CURP completo cae en PdfCURPInformation" {
    let r = baml.sap.parse<CurpResult>(`{"Names": ["JUAN", "CARLOS"], "FirstLastName": "PEREZ", "SecondLastName": "LOPEZ", "CURP": "XEXX010101HNEXXXA4", "RegistrationDate": "2010-01-01", "RegistrationState": "JALISCO", "Folio": "000123456", "BarCode": 456}`);
    match (r) {
        PdfCURPInformation => {
            assert.equal(r.CURP, "XEXX010101HNEXXXA4");
            assert.equal(r.RegistrationState, "JALISCO");
            // Folio es string: conserva los ceros a la izquierda.
            assert.equal(r.Folio, "000123456");
        },
        MissingInformation => assert.is_true(false),
        NotACURP => assert.is_true(false),
    }
}

test "respuesta con markdown y coma final se repara" {
    let r = baml.sap.parse<CurpResult>(`Aquí están los datos:
{"Names": ["JUAN"], "FirstLastName": "PEREZ", "SecondLastName": "LOPEZ", "CURP": "XEXX010101HNEXXXA4", "RegistrationDate": "2010-01-01", "RegistrationState": "JALISCO", "Folio": "000123456", "BarCode": 2,}`);
    match (r) {
        PdfCURPInformation => assert.equal(r.Names.length(), 1),
        MissingInformation => assert.is_true(false),
        NotACURP => assert.is_true(false),
    }
}

test "missing_information cae en MissingInformation" {
    let r = baml.sap.parse<CurpResult>(`{"Kind": "missing_information", "Reason": "No aparece el código de barras"}`);
    match (r) {
        MissingInformation => assert.equal(r.Reason, "No aparece el código de barras"),
        PdfCURPInformation => assert.is_true(false),
        NotACURP => assert.is_true(false),
    }
}

test "not_a_curp cae en NotACURP" {
    let r = baml.sap.parse<CurpResult>(`{"Kind": "not_a_curp", "Reason": "Es un ticket de compra"}`);
    match (r) {
        NotACURP => assert.equal(r.Reason, "Es un ticket de compra"),
        PdfCURPInformation => assert.is_true(false),
        MissingInformation => assert.is_true(false),
    }
}

// Casos que deben fallar: si alguno dejara de lanzar ParseError, `failed` queda en false y el test truena.

test "CURP incompleto sin Kind lanza ParseError" {
    let failed = {
        baml.sap.parse<CurpResult>(`{"Names": ["JUAN"], "CURP": "XEXX010101HNEXXXA4"}`);
        false
    } catch (e) {
        baml.errors.ParseError => true,
    };
    assert.is_true(failed)
}

test "Reason sin Kind lanza ParseError" {
    let failed = {
        baml.sap.parse<CurpResult>(`{"Reason": "Es un ticket"}`);
        false
    } catch (e) {
        baml.errors.ParseError => true,
    };
    assert.is_true(failed)
}

test "BarCode fuera de rango de int lanza ParseError" {
    let failed = {
        baml.sap.parse<CurpResult>(`{"Names": ["JUAN"], "FirstLastName": "PEREZ", "SecondLastName": "LOPEZ", "CURP": "XEXX010101HNEXXXA4", "RegistrationDate": "2010-01-01", "RegistrationState": "JALISCO", "Folio": "000123456", "BarCode": 12345678901234567890}`);
        false
    } catch (e) {
        baml.errors.ParseError => true,
    };
    assert.is_true(failed)
}

test "texto sin JSON lanza ParseError" {
    let failed = {
        baml.sap.parse<CurpResult>(`No puedo leer este documento`);
        false
    } catch (e) {
        baml.errors.ParseError => true,
    };
    assert.is_true(failed)
}
