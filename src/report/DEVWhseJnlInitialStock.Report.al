report 83261 "DEV Whse. Jnl. Initial Stock"
{
    Caption = 'Import Advanced Warehouse Initial Stock';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;
    Permissions = tabledata "Whse. Item Tracking Line" = rimd;

    dataset
    {
        dataitem(ImportData; Integer)
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnPreDataItem()
            var
                WhseJnlLine: Record "Warehouse Journal Line";
                TextMandatoryErr: Label '%1 must have value.', Comment = '%1 value';
                FilenameLbl: Label 'Filename';
            begin
                if JnlTemplateName = '' then
                    Error(TextMandatoryErr, WhseJnlLine.FieldCaption("Journal Template Name"));

                if JnlBatchName = '' then
                    Error(TextMandatoryErr, WhseJnlLine.FieldCaption("Journal Batch Name"));

                if Filename = '' then
                    Error(TextMandatoryErr, FilenameLbl);

                if DocNo = '' then
                    DocNo := 'INV_' + Format(Today());

                if PostingDate = 0D then
                    PostingDate := Today();
            end;

            trigger OnAfterGetRecord()
            var
                TempCSVBuffer: Record "CSV Buffer" temporary;
                WhseJnlLine: Record "Warehouse Journal Line";
                Item: Record Item;
                IUOM: Record "Item Unit of Measure";
                Bin: Record Bin;
                WhseJnlTemplate: Record "Warehouse Journal Template";
                WhseJnlBatch: Record "Warehouse Journal Batch";
                LocationCode: Code[10];
                Qty: Decimal;
                LotNo, SerialNo : Code[20];
                ExpDate: Date;
                LineNo, NoOfRecs, CurrRec : Integer;
                Window: Dialog;
                TextWindowLbl: Label 'Processing data #1################', Comment = '#1 show data status';
                TextDoneLbl: Label 'Done!';
            begin
                TempCSVBuffer.DeleteAll();
                TempCSVBuffer.LoadDataFromStream(CSVInStream, ';');
                if HeaderIncluded then
                    TempCSVBuffer.SetFilter("Line No.", '>=%1', 2);
                if TempCSVBuffer.FindSet() then begin
                    if GuiAllowed() then
                        Window.Open(TextWindowLbl);
                    NoOfRecs := TempCSVBuffer.Count();

                    LineNo := GetLineNo();

                    repeat
                        if GuiAllowed() then begin
                            CurrRec += 1;
                            Window.Update(1, Format(CurrRec) + ' of ' + Format(NoOfRecs));
                        end;

                        if TempCSVBuffer."Field No." = 1 then begin
                            Clear(WhseJnlLine);
                            WhseJnlLine.Init();
                            WhseJnlLine.Validate("Journal Template Name", JnlTemplateName);
                            WhseJnlLine.Validate("Journal Batch Name", JnlBatchName);
                            WhseJnlLine."Line No." := LineNo;
                            WhseJnlLine.Validate("Registering Date", PostingDate);
                            LocationCode := CopyStr(TempCSVBuffer.Value, 1, 10);
                            WhseJnlLine.Validate("Location Code", LocationCode);

                            LotNo := '';
                            SerialNo := '';
                            ExpDate := 0D;
                            LineNo += 10000;
                        end;

                        case TempCSVBuffer."Field No." of
                            2:
                                WhseJnlLine.Validate("Item No.", TempCSVBuffer.Value);

                            3:
                                if TempCSVBuffer.Value <> '' then
                                    WhseJnlLine.Validate("Variant Code", TempCSVBuffer.Value);

                            4:
                                begin
                                    Item.Get(WhseJnlLine."Item No.");
                                    Bin.Get(WhseJnlLine."Location Code", TempCSVBuffer.Value);
                                    if Item."Warehouse Class Code" <> Bin."Warehouse Class Code" then begin
                                        CLEAR(Bin);
                                        Bin.SetCurrentKey("Location Code", "Warehouse Class Code", "Bin Ranking");
                                        Bin.SetRange("Location Code", WhseJnlLine."Location Code");
                                        Bin.SetRange("Warehouse Class Code", Item."Warehouse Class Code");
                                        if Bin.FindFirst() then
                                            WhseJnlLine.Validate("Bin Code", Bin.Code);
                                    end else
                                        WhseJnlLine.Validate("Bin Code", TempCSVBuffer.Value);
                                end;

                            5:
                                begin
                                    Evaluate(Qty, TempCSVBuffer.Value);
                                    WhseJnlLine.Validate(Quantity, Qty);
                                    if Qty >= 0 then
                                        WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Positive Adjmt."
                                    else
                                        WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::"Negative Adjmt.";

                                    WhseJnlTemplate.Get(WhseJnlLine."Journal Template Name");
                                    WhseJnlBatch.Get(WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", WhseJnlLine."Location Code");

                                    WhseJnlLine."Source Code" := WhseJnlTemplate."Source Code";
                                    WhseJnlLine."Reason Code" := WhseJnlBatch."Reason Code";
                                    WhseJnlLine.SetUpAdjustmentBin();
                                    WhseJnlLine.Insert(true);
                                end;

                            6:
                                if TempCSVBuffer.Value <> '' then begin
                                    IUOM.Get(WhseJnlLine."Item No.", TempCSVBuffer.Value);

                                    if WhseJnlLine."Unit of Measure Code" <> TempCSVBuffer.Value then begin
                                        WhseJnlLine.Validate("Unit of Measure Code", TempCSVBuffer.Value);
                                        WhseJnlLine.Modify();
                                    end;
                                end;

                            7:
                                LotNo := CopyStr(TempCSVBuffer.Value, 1, 20);
                            8:
                                SerialNo := CopyStr(TempCSVBuffer.Value, 1, 20);
                            9:
                                begin
                                    if TempCSVBuffer.Value <> '' then
                                        Evaluate(ExpDate, TempCSVBuffer.Value);

                                    if (LotNo <> '') or (SerialNo <> '') then
                                        SetTrackingLine(WhseJnlLine, LotNo, SerialNo, ExpDate);
                                end;
                        end;
                    until TempCSVBuffer.Next() = 0;

                    if GuiAllowed() then begin
                        Window.Close();
                        Message(TextDoneLbl);
                    end;
                end;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(StockFile)
                {
                    Caption = 'Import data from...';
                    field(SetStockFile; Filename)
                    {
                        Caption = 'Select file to import';
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Select file to import field';

                        trigger OnAssistEdit()
                        var
                            CSVLbl: Label 'CSV Files (*.csv)|*.csv';
                        begin
                            UploadIntoStream('Import', '', CSVLbl, Filename, CSVInStream);
                        end;
                    }
                }

                group(Import)
                {
                    Caption = 'Import data to...';
                    field(SetJnlTemplateName; JnlTemplateName)
                    {
                        Caption = 'Select Warehouse Jnl. Template';
                        ApplicationArea = All;
                        TableRelation = "Warehouse Journal Template" where(Type = filter(Item));
                        ToolTip = 'Specifies the value of the Select Whse. Jnl. Template field';
                    }
                    field(SetJnlBatch; JnlBatchName)
                    {
                        Caption = 'Select Warehouse Jnl. Batch Name';
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Select Whse. Jnl. Batch Name field';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            WhsenlBatch: Record "Warehouse Journal Batch";
                            WhseJnlPage: Page "Whse. Journal Batches List";
                        begin
                            WhsenlBatch.FilterGroup(2);
                            WhsenlBatch.SetRange("Journal Template Name", JnlTemplateName);
                            WhsenlBatch.FilterGroup(0);
                            if WhsenlBatch.FindSet() then begin
                                Clear(WhseJnlPage);
                                WhseJnlPage.SetTableView(WhsenlBatch);
                                WhseJnlPage.LookupMode := true;
                                WhseJnlPage.Editable := false;
                                if WhseJnlPage.RunModal() = Action::LookupOK then begin
                                    WhseJnlPage.GetRecord(WhsenlBatch);
                                    JnlBatchName := WhsenlBatch.Name;
                                end;
                            end;
                        end;

                        trigger OnValidate()
                        var
                            WhseJnlBatch: Record "Warehouse Journal Batch";
                        begin
                            WhseJnlBatch.Get(JnlTemplateName, JnlBatchName);
                        end;
                    }
                    field(DocumentNo; DocNo)
                    {
                        Caption = 'Document No.';
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Document No. field';
                    }
                    field(PostDate; PostingDate)
                    {
                        Caption = 'Posting Date';
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Posting Date field';
                    }
                    field(IsHeaderIncluded; HeaderIncluded)
                    {
                        Caption = 'Include Header';
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Include Header field';
                    }
                }
            }
        }

        trigger OnOpenPage()
        var
            SourceCodeSetup: Record "Source Code Setup";
            WhseJnlTemplate: Record "Warehouse Journal Template";
        begin
            SourceCodeSetup.Get();
            WhseJnlTemplate.SetCurrentKey(Type, "Source Code");
            WhseJnlTemplate.SetRange(Type, WhseJnlTemplate.Type::Item);
            WhseJnlTemplate.SetRange("Source Code", SourceCodeSetup."Whse. Item Journal");
            WhseJnlTemplate.FindFirst();
            JnlTemplateName := WhseJnlTemplate.Name;
        end;
    }

    local procedure GetLineNo(): Integer
    var
        WhseJnlLine: Record "Warehouse Journal Line";
    begin
        WhseJnlLine.Reset();
        WhseJnlLine.SetRange("Journal Template Name", JnlTemplateName);
        WhseJnlLine.SetRange("Journal Batch Name", JnlBatchName);
        if WhseJnlLine.FindLast() then
            exit(WhseJnlLine."Line No." + 10000)
        else
            exit(10000);
    end;

    local procedure SetTrackingLine(var WhseJnlLine: Record "Warehouse Journal Line"; LotNo: Code[50]; SerialNo: Code[50]; ExpDate: Date)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        EntryNo: Integer;
    begin
        if (LotNo <> '') or (SerialNo <> '') then begin
            EntryNo := 1;

            Clear(WhseItemTrackingLine);
            if WhseItemTrackingLine.FindLast() then
                EntryNo += WhseItemTrackingLine."Entry No.";

            CLEAR(WhseItemTrackingLine);
            WhseItemTrackingLine."Entry No." := EntryNo;
            WhseItemTrackingLine.Insert(true);
            WhseItemTrackingLine.Validate("Item No.", WhseJnlLine."Item No.");
            WhseItemTrackingLine.Validate("Variant Code", WhseJnlLine."Variant Code");
            WhseItemTrackingLine.Validate("Location Code", WhseJnlLine."Location Code");
            WhseItemTrackingLine.Validate("Quantity (Base)", WhseJnlLine."Qty. (Base)");
            WhseItemTrackingLine.Validate("Source Type", Database::"Warehouse Journal Line");
            WhseItemTrackingLine.Validate("Source ID", WhseJnlLine."Journal Batch Name");
            WhseItemTrackingLine.Validate("Source Batch Name", WhseJnlLine."Journal Template Name");
            WhseItemTrackingLine.Validate("Source Ref. No.", WhseJnlLine."Line No.");

            if LotNo <> '' then
                WhseItemTrackingLine.Validate("Lot No.", LotNo);

            if SerialNo <> '' then
                WhseItemTrackingLine.Validate("Serial No.", SerialNo);

            WhseItemTrackingLine."Expiration Date" := ExpDate;
            WhseItemTrackingLine.Modify(true);
        END;
    end;

    internal procedure SetWhseJournal(SetWhseJnlTemplate: Code[20]; SetWhseJnlBatchName: Code[10])
    begin
        JnlTemplateName := SetWhseJnlTemplate;
        JnlBatchName := SetWhseJnlBatchName;
    end;

    var
        CSVInStream: InStream;
        JnlTemplateName, DocNo : Code[20];
        JnlBatchName: Code[10];
        PostingDate: Date;
        Filename: Text;
        HeaderIncluded: Boolean;
}