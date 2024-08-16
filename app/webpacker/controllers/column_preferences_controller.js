import { Controller } from "stimulus";

// Manage column visibility according to checkbox selection
//
export default class ColumnPreferencesController extends Controller {
  recordedCells = {}

  connect() {
    this.table = document.querySelector('table[data-column-preferences-target="table"]');
    this.cols = Array.from(this.table.querySelectorAll('col'));
    this.colSpanCells = Array.from(this.table.querySelectorAll('th[colspan],td[colspan]'));
    this.recordedCells = [...this.colSpanCells];
    // Initialise data-default-col-span
    this.colSpanCells.forEach((cell)=> {
      cell.dataset.defaultColSpan ||= cell.colSpan;
    });

    this.checkboxes = Array.from(this.element.querySelectorAll("input[type=checkbox]"));
    for (const element of this.checkboxes) {
      // On initial load
      this.#showHideColumn(element);
      // On checkbox changed
      element.addEventListener("change", this.#showHideColumn.bind(this));
    }
  }

  registerCell() {
      const registeredElements = this.recordedCells;
      const newCells = this.colSpanCells.filter(
        (cell) => !registeredElements.includes(cell)
      );

      console.log("Identified new cells:", newCells);

      if (newCells.length > 0) {
        newCells.forEach(cell => {
          cell.dataset.defaultColSpan ||= cell.colSpan;
          const hiddenColCount = this.checkboxes.filter((checkbox) => !checkbox.checked).length;
          const span = parseInt(cell.dataset.defaultColSpan, 10) - hiddenColCount;
          cell.colSpan = span;
          this.recordedCells.push(cell);
        });
        console.log("Updated recordedCells:", this.recordedCells);
      }
  }

  // private

  #showHideColumn(e) {
    const element = e.target || e;
    const name = element.dataset.columnName;

    this.table.classList.toggle(`hide-${name}`, !element.checked);

    // Reset cell colspans
    const hiddenColCount = this.checkboxes.filter((checkbox)=> !checkbox.checked).length;
    for(const cell of this.recordedCells) {
      const span = parseInt(cell.dataset.defaultColSpan, 10) - hiddenColCount;
      cell.colSpan = span;
    };
  }

  #showHideElement(element, show) {
    element.style.display = show ? "" : "none";
  }
}
