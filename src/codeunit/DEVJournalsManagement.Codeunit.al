codeunit 83260 "DEV Journals Management"
{
    procedure DeleteItemJournalData(SetItemJnlTemplate: Code[20]; SetItemJnlBatchName: Code[10])
    var
        ReservEntry: Record "Reservation Entry";
        ItemJnlLine: Record "Item Journal Line";
        DeleteAllQst: Label 'Delete all data from current journal?';
    begin
        if not Confirm(DeleteAllQst, false) then
            exit;

        ReservEntry.SetRange("Source Type", Database::"Item Journal Line");
        ReservEntry.SetRange("Source ID", SetItemJnlTemplate);
        ReservEntry.SetRange("Source Batch Name", SetItemJnlBatchName);
        ReservEntry.DeleteAll();

        ItemJnlLine.SetRange("Journal Template Name", SetItemJnlTemplate);
        ItemJnlLine.SetRange("Journal Batch Name", SetItemJnlBatchName);
        ItemJnlLine.DeleteAll();
    end;

    internal procedure DemoItemJnlInitialStockFile();
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        CSVInStream: InStream;
        Filename: Text;
        FilenameLbl: Label 'Item_Jounal_Initial_Stock.csv';
        CSVLbl: Label 'CSV Files (*.csv)|*.csv';
    begin
        TempCSVBuffer.InsertEntry(1, 1, 'Location Code');
        TempCSVBuffer.InsertEntry(1, 2, 'Item No.');
        TempCSVBuffer.InsertEntry(1, 3, 'Variant Code');
        TempCSVBuffer.InsertEntry(1, 4, 'Quantity');
        TempCSVBuffer.InsertEntry(1, 5, 'Unit of Measure Code');
        TempCSVBuffer.InsertEntry(1, 6, 'Unit Cost');
        TempCSVBuffer.InsertEntry(1, 7, 'Lot No.');
        TempCSVBuffer.InsertEntry(1, 8, 'Serial No.');
        TempCSVBuffer.InsertEntry(1, 9, 'Expiration Date');

        TempCSVBuffer.SaveDataToBlob(TempBlob, ';');
        TempBlob.CreateInStream(CSVInStream);
        FileName := FilenameLbl;
        DownloadFromStream(CSVInStream, 'Export', '', CSVLbl, Filename);
    end;

    internal procedure DemoWhseJnlInitialStockFile();
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        CSVInStream: InStream;
        Filename: Text;
        FilenameLbl: Label 'Whse_Journal_Initial_Stock.csv';
        CSVLbl: Label 'CSV Files (*.csv)|*.csv';
    begin
        TempCSVBuffer.InsertEntry(1, 1, 'Location Code');
        TempCSVBuffer.InsertEntry(1, 2, 'Item No.');
        TempCSVBuffer.InsertEntry(1, 3, 'Variant Code');
        TempCSVBuffer.InsertEntry(1, 4, 'Bin');
        TempCSVBuffer.InsertEntry(1, 5, 'Quantity');
        TempCSVBuffer.InsertEntry(1, 6, 'Unit of Measure Code');
        TempCSVBuffer.InsertEntry(1, 7, 'Lot No.');
        TempCSVBuffer.InsertEntry(1, 8, 'Serial No.');
        TempCSVBuffer.InsertEntry(1, 9, 'Expiration Date');

        TempCSVBuffer.SaveDataToBlob(TempBlob, ';');
        TempBlob.CreateInStream(CSVInStream);
        FileName := FilenameLbl;
        DownloadFromStream(CSVInStream, 'Export', '', CSVLbl, Filename);
    end;
}
