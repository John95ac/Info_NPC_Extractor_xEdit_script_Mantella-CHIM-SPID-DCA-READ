unit UserScript;

function Process(e: IInterface): integer;
    var
        rec: IInterface;
        sPath, sPathFlags: string;
        sPath31: string;

    begin

        Result := 0;

        rec := Signature(e);
        sPath := Name(e);

        if (rec = 'NPC_') then begin

            sPathFlags := 'ACBS\Flags';
            sPath31 := 'ACBS\Flags\Invulnerable';

            // ELIMINAR LA BANDERA 'INVULNERABLE'
            if ElementExists(e, sPath31) then
                begin
                    SetElementEditValues(e, sPath31, 0);
                    AddMessage(sPath + ' ya no es Invulnerable');
                end;

        end; // fin de la condición

    end; // fin de la función

// Limpieza
function Finalize: integer;
    begin

        Result := 1;

    end; // fin de la función

end. // fin del script
