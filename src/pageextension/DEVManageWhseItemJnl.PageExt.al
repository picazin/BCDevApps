pageextension 83262 "DEV Manage Whse. Item Jnl" extends "Whse. Item Journal"
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
                    ImportStock: Report "DEV Whse. Jnl. Initial Stock";
                begin
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
                    JnlMngmt.DemoWhseJnlInitialStockFile();
                end;
            }
        }
    }
}