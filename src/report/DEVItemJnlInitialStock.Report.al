report 83260 "DEV Item Jnl. Initial Stock"
{
    Caption = 'Import Simple Warehouse Initial Stock';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(ImportData; Integer)
        {
            DataItemTableView = sorting(Number);
            MaxIteration = 1;

            trigger OnPreDataItem()
            var
                ItemJnlLine: Record "Item Journal Line";
                TextMandatoryErr: Label '%1 must have value.', Comment = '%1 value';
                FilenameLbl: Label 'Filename';
            begin
                if ItemJnlTemplate = '' then
                    Error(TextMandatoryErr, ItemJnlLine.FieldCaption("Journal Template Name"));

                if ItemJnlBatchName = '' then
                    Error(TextMandatoryErr, ItemJnlLine.FieldCaption("Journal Batch Name"));

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
                ItemJnlLine: Record "Item Journal Line";
                IUOM: Record "Item Unit of Measure";
                LocationCode: Code[10];
                Qty, UnitCost : Decimal;
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
                            Clear(ItemJnlLine);
                            ItemJnlLine.Init();
                            ItemJnlLine.Validate("Journal Template Name", ItemJnlTemplate);
                            ItemJnlLine.Validate("Journal Batch Name", ItemJnlBatchName);
                            ItemJnlLine."Line No." := LineNo;
                            ItemJnlLine.Validate("Posting Date", PostingDate);
                            ItemJnlLine."Document No." := DocNo;
                            LocationCode := CopyStr(TempCSVBuffer.Value, 1, 10);

                            LotNo := '';
                            SerialNo := '';
                            ExpDate := 0D;
                            LineNo += 10000;
                        end;

                        case TempCSVBuffer."Field No." of
                            2:
                                begin
                                    ItemJnlLine.Validate("Item No.", TempCSVBuffer.Value);
                                    ItemJnlLine.Validate("Location Code", LocationCode);
                                end;

                            3:
                                if TempCSVBuffer.Value <> '' then
                                    ItemJnlLine.Validate("Variant Code", TempCSVBuffer.Value);

                            4:
                                begin
                                    Evaluate(Qty, TempCSVBuffer.Value);
                                    if Qty < 0 then
                                        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Negative Adjmt.")
                                    else
                                        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.");
                                    ItemJnlLine.Validate(Quantity, Qty);
                                end;

                            5:
                                begin
                                    IUOM.Get(ItemJnlLine."Item No.", TempCSVBuffer.Value);
                                    ItemJnlLine.Validate("Unit of Measure Code", TempCSVBuffer.Value);
                                end;

                            6:
                                begin
                                    if TempCSVBuffer.Value <> '' then begin
                                        Evaluate(UnitCost, TempCSVBuffer.Value);
                                        ItemJnlLine.Validate("Unit Amount", UnitCost);
                                        ItemJnlLine.Validate("Unit Cost", UnitCost);
                                    end;
                                    ItemJnlLine.Insert(true);
                                end;
                            7:
                                LotNo := CopyStr(TempCSVBuffer.Value, 1, 20);
                            8:
                                SerialNo := CopyStr(TempCSVBuffer.Value, 1, 20);
                            9:
                                begin
                                    Clear(ExpDate);
                                    if TempCSVBuffer.Value <> '' then
                                        Evaluate(ExpDate, TempCSVBuffer.Value);

                                    if (LotNo <> '') or (SerialNo <> '') then
                                        SetTrackingLine(ItemJnlLine, LotNo, SerialNo, ExpDate);
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
                    field(SetItemJnlTemplate; ItemJnlTemplate)
                    {
                        Caption = 'Select Item Jnl. Template';
                        ApplicationArea = All;
                        TableRelation = "Item Journal Template" where(Type = filter(Item), Recurring = const(false));
                        ToolTip = 'Specifies the value of the Select Item Jnl. Template field';
                    }
                    field(SetItemJnlBatch; ItemJnlBatchName)
                    {
                        Caption = 'Select Item Jnl. Batch Name';
                        ApplicationArea = All;
                        ToolTip = 'Specifies the value of the Select Item Jnl. Batch Name field';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            ItemJnlBatch: Record "Item Journal Batch";
                            ItemJnlPage: Page "Item Journal Batches";
                        begin
                            ItemJnlBatch.FilterGroup(2);
                            ItemJnlBatch.SetRange("Journal Template Name", ItemJnlTemplate);
                            ItemJnlBatch.FilterGroup(0);
                            if ItemJnlBatch.FindSet() then begin
                                Clear(ItemJnlPage);
                                ItemJnlPage.SetTableView(ItemJnlBatch);
                                ItemJnlPage.LookupMode := true;
                                ItemJnlPage.Editable := false;
                                if ItemJnlPage.RunModal() = Action::LookupOK then begin
                                    ItemJnlPage.GetRecord(ItemJnlBatch);
                                    ItemJnlBatchName := ItemJnlBatch.Name;
                                end;
                            end;
                        end;

                        trigger OnValidate()
                        var
                            ItemJnlBatch: Record "Item Journal Batch";
                        begin
                            ItemJnlBatch.Get(ItemJnlTemplate, ItemJnlBatchName);
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
    }

    local procedure GetLineNo(): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.Reset();
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlTemplate);
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlBatchName);
        if ItemJnlLine.FindLast() then
            exit(ItemJnlLine."Line No." + 10000)
        else
            exit(10000);
    end;

    local procedure SetTrackingLine(var ItemJnlLine: Record "Item Journal Line"; LotNo: Code[50]; SerialNo: Code[50]; ExpDate: Date)
    var
        TempReservEntry: Record "Reservation Entry" temporary;
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        ReservStatus: Enum "Reservation Status";
    begin
        TempReservEntry.Init();
        TempReservEntry."Entry No." := 1;
        TempReservEntry."Lot No." := LotNo;
        TempReservEntry."Serial No." := SerialNo;
        TempReservEntry.Quantity := ItemJnlLine."Quantity (Base)";
        TempReservEntry."Expiration Date" := ExpDate;
        TempReservEntry.Insert();

        CreateReservEntry.SetDates(0D, TempReservEntry."Expiration Date");
        CreateReservEntry.CreateReservEntryFor(Database::"Item Journal Line", ItemJnlLine."Entry Type".AsInteger(), ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name", 0, ItemJnlLine."Line No.", ItemJnlLine."Qty. per Unit of Measure",
          TempReservEntry.Quantity, TempReservEntry.Quantity * ItemJnlLine."Qty. per Unit of Measure", TempReservEntry);
        CreateReservEntry.CreateEntry(ItemJnlLine."Item No.", ItemJnlLine."Variant Code", ItemJnlLine."Location Code", '', 0D, 0D, 0, ReservStatus::Surplus);
    end;

    internal procedure SetItemJournal(SetItemJnlTemplate: Code[20]; SetItemJnlBatchName: Code[10])
    begin
        ItemJnlTemplate := SetItemJnlTemplate;
        ItemJnlBatchName := SetItemJnlBatchName;
    end;

    var
        CSVInStream: InStream;
        ItemJnlTemplate, DocNo : Code[20];
        ItemJnlBatchName: Code[10];
        PostingDate: Date;
        Filename: Text;
        HeaderIncluded: Boolean;
}