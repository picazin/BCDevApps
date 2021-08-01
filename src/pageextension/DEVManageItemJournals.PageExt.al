pageextension 83260 "DEV Manage Item Journals" extends "Item Journal Batches"
{
    actions
    {
        addlast(processing)
        {
            action(DEVImportInitialStock)
            {
                ApplicationArea = All;
                Caption = 'Import Initial Stock';
                Image = InventoryJournal;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Import initial stock for selected journal.';

                trigger OnAction()
                var
                    ImportStock: Report "DEV Item Jnl. Initial Stock";
                begin
                    ImportStock.SetItemJournal(Rec."Journal Template Name", Rec.Name);
                    ImportStock.RunModal();
                end;
            }
            action(DEVDemoInitialStockFile)
            {
                ApplicationArea = All;
                Caption = 'Create Initial Stock Demo File';
                Image = FileContract;
                ToolTip = 'Create initial stock file for use with Importe Initial Stock Action.';

                trigger OnAction()
                var
                    JnlMngmt: Codeunit "DEV Journals Management";
                begin
                    JnlMngmt.DemoItemJnlInitialStockFile();
                end;
            }
            action(DEVDeleteJournal)
            {
                ApplicationArea = All;
                Caption = 'Delete Journal';
                Image = DeleteExpiredComponents;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Delete all data for selected journal.';

                trigger OnAction()
                var
                    JnlMngmt: Codeunit "DEV Journals Management";
                begin
                    JnlMngmt.DeleteItemJournalData(Rec."Journal Template Name", Rec.Name);
                end;
            }
        }
    }
}