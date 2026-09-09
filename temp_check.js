
    document.addEventListener("DOMContentLoaded", function () {
      var nameLabel = document.getElementById("userNameLabel");
      if (nameLabel && nameLabel.innerText.trim()) {
        var initial = nameLabel.innerText.trim().charAt(0).toUpperCase();
        var avatar = document.getElementById("userAvatarInitial");
        if (avatar) avatar.innerText = initial;
      }
    });

    function submitBspAction(actionName) {
      var actField = document.getElementById('actionField');
      if (actField) {
        actField.value = actionName;
      }
      var overlay = document.getElementById('globalLoadingOverlay');
      if (overlay) {
        overlay.classList.remove('hidden');
      }
      var form = document.getElementById('bpForm');
      if (form) {
        form.submit();
      }
    }

    function syncFilterToForm(inputEl, targetField) {
      var target = document.getElementById('form' + targetField.charAt(0).toUpperCase() + targetField.slice(1));
      if (target) {
        target.value = inputEl.value;
      }
    }

    function handleBpSearchKeyup(e) {
      if (e.key === "Enter" || e.keyCode === 13) {
        executeBpSearch();
      }
    }

    function handleSearchByChange(val) {
      var termInput = document.getElementById('searchBpTerm');
      var termLabel = document.getElementById('searchBpTermLabel');
      if (!termInput) return;
      if (val === 'TAX') {
        termLabel.innerText = "Tax Number / NPWP";
        termInput.placeholder = "Enter Tax Number / NPWP (e.g. 01.234.567)...";
      } else if (val === 'NAME') {
        termLabel.innerText = "Partner Name";
        termInput.placeholder = "Enter Company / Partner Name...";
      } else if (val === 'NUMBER') {
        termLabel.innerText = "Business Partner Number";
        termInput.placeholder = "Enter SAP BP Number (e.g. 100234)...";
      } else {
        termLabel.innerText = "Business Partner";
        termInput.placeholder = "Enter Tax Number / NPWP or Name...";
      }
    }

    function handleFindCategoryChange(val) {
      if (val === '2') selectBpCategory('2');
      else if (val === '3') selectBpCategory('1');
      else if (val === '4') selectBpCategory('3');
    }

    function executeBpSearch() {
      var term = document.getElementById('searchBpTerm') ? document.getElementById('searchBpTerm').value.trim() : '';
      var by = document.getElementById('searchBpBy') ? document.getElementById('searchBpBy').value : 'ALL';
      var fTax = document.getElementById('formTaxNum');
      var fName = document.getElementById('formName1');
      var fCity = document.getElementById('formCity');
      var filterCityVal = document.getElementById('filterCity') ? document.getElementById('filterCity').value.trim() : '';
      var filterNameVal = document.getElementById('filterName1') ? document.getElementById('filterName1').value.trim() : '';

      if (term) {
        if (by === 'TAX') {
          if (fTax) fTax.value = term;
        } else if (by === 'NAME') {
          if (fName) fName.value = term;
        } else {
          // If contains numbers and dots/dashes, treat as tax number
          if (/[0-9]{3,}/.test(term) && !fTax.value) {
            fTax.value = term;
          } else if (!fName.value) {
            fName.value = term;
          }
        }
      }

      if (filterNameVal && fName) fName.value = filterNameVal;
      if (filterCityVal && fCity) fCity.value = filterCityVal;

      submitBspAction('CHECK_DUP');
    }

    function useDuplicateAsRef(name, tax, city, country) {
      var fName = document.getElementById('formName1');
      var fTax = document.getElementById('formTaxNum');
      var fCity = document.getElementById('formCity');
      var fCountry = document.getElementById('formCountry');

      if (name && fName) fName.value = name;
      if (tax && tax !== 'N/A' && fTax) fTax.value = tax;
      if (city && fCity) fCity.value = city;
      if (country && fCountry) {
        for (var i = 0; i < fCountry.options.length; i++) {
          if (fCountry.options[i].value === country) {
            fCountry.selectedIndex = i;
            break;
          }
        }
      }
      showToast("Data referensi berhasil dimasukkan ke formulir.", "success");
    }

    function resetDuplicateSearch() {
      var sTerm = document.getElementById('searchBpTerm');
      var fName = document.getElementById('filterName1');
      var fCity = document.getElementById('filterCity');
      if (sTerm) sTerm.value = "";
      if (fName) fName.value = "";
      if (fCity) fCity.value = "";
      showToast("Filter pencarian dibersihkan.", "info");
    }

    function selectBpCategory(catVal) {
      var sel = document.getElementById('formBpCategory');
      if (sel) sel.value = catVal;
      syncCategoryButtons(catVal);
    }

    function syncCategoryButtons(catVal) {
      var bOrg = document.getElementById('catBtnOrg');
      var bPerson = document.getElementById('catBtnPerson');
      var bGroup = document.getElementById('catBtnGroup');

      var activeCls = "bg-white text-slate-900 shadow-xs";
      var inactiveCls = "text-slate-500 hover:text-slate-800";

      if (bOrg) {
        bOrg.classList.remove("bg-white", "text-slate-900", "shadow-xs", "text-slate-500", "hover:text-slate-800");
        if (catVal === '2') bOrg.classList.add("bg-white", "text-slate-900", "shadow-xs");
        else bOrg.classList.add("text-slate-500", "hover:text-slate-800");
      }
      if (bPerson) {
        bPerson.classList.remove("bg-white", "text-slate-900", "shadow-xs", "text-slate-500", "hover:text-slate-800");
        if (catVal === '1') bPerson.classList.add("bg-white", "text-slate-900", "shadow-xs");
        else bPerson.classList.add("text-slate-500", "hover:text-slate-800");
      }
      if (bGroup) {
        bGroup.classList.remove("bg-white", "text-slate-900", "shadow-xs", "text-slate-500", "hover:text-slate-800");
        if (catVal === '3') bGroup.classList.add("bg-white", "text-slate-900", "shadow-xs");
        else bGroup.classList.add("text-slate-500", "hover:text-slate-800");
      }
    }

    function resetBpFormFields() {
      var form = document.getElementById('bpForm');
      if (!form) return;
      var inputs = form.querySelectorAll('input:not([type=hidden]):not([readonly]), textarea:not([readonly])');
      for (var i = 0; i < inputs.length; i++) {
        inputs[i].value = '';
      }
      showToast("Formulir telah di-reset.", "info");
    }

    function switchBpTab(tab) {
      var btnAll = document.getElementById("tabAllBtn");
      var btnGeneral = document.getElementById("tabGeneralBtn");
      var btnRoles = document.getElementById("tabRolesBtn");
      var btnAddress = document.getElementById("tabAddressBtn");
      var btnFinance = document.getElementById("tabFinanceBtn");
      var btnSteward = document.getElementById("tabStewardBtn");

      var secGeneral = document.getElementById("sectionGeneral");
      var secRoles = document.getElementById("sectionRoles");
      var secAddress = document.getElementById("sectionAddress");
      var secFinance = document.getElementById("sectionFinance");
      var secSteward = document.getElementById("sectionSteward");

      var baseCls = "h-9 px-5 rounded-full font-extrabold text-xs " +
        "inline-flex items-center justify-center whitespace-nowrap transition-all cursor-pointer ";
      var activeStyle = baseCls + "bg-gradient-to-r from-emerald-500 to-emerald-600 text-white shadow-xs";
      var inactiveStyle = baseCls + "text-slate-600 hover:text-slate-900 bg-white/80 hover:bg-white border border-slate-200/80 shadow-2xs";

      if (btnAll) btnAll.className = (tab === 'ALL') ? activeStyle : inactiveStyle;
      if (btnGeneral) btnGeneral.className = (tab === 'GENERAL') ? activeStyle : inactiveStyle;
      if (btnRoles) btnRoles.className = (tab === 'ROLES') ? activeStyle : inactiveStyle;
      if (btnAddress) btnAddress.className = (tab === 'ADDRESS') ? activeStyle : inactiveStyle;
      if (btnFinance) btnFinance.className = (tab === 'FINANCE') ? activeStyle : inactiveStyle;
      if (btnSteward) btnSteward.className = (tab === 'STEWARD') ? activeStyle : inactiveStyle;

      if (tab === 'ALL') {
        if (secGeneral) secGeneral.classList.remove("hidden");
        if (secRoles) secRoles.classList.remove("hidden");
        if (secAddress) secAddress.classList.remove("hidden");
        if (secFinance) secFinance.classList.remove("hidden");
        if (secSteward) secSteward.classList.remove("hidden");
      } else if (tab === 'GENERAL') {
        if (secGeneral) secGeneral.classList.remove("hidden");
        if (secRoles) secRoles.classList.add("hidden");
        if (secAddress) secAddress.classList.add("hidden");
        if (secFinance) secFinance.classList.add("hidden");
        if (secSteward) secSteward.classList.add("hidden");
      } else if (tab === 'ROLES') {
        if (secGeneral) secGeneral.classList.add("hidden");
        if (secRoles) secRoles.classList.remove("hidden");
        if (secAddress) secAddress.classList.add("hidden");
        if (secFinance) secFinance.classList.add("hidden");
        if (secSteward) secSteward.classList.add("hidden");
      } else if (tab === 'ADDRESS') {
        if (secGeneral) secGeneral.classList.add("hidden");
        if (secRoles) secRoles.classList.add("hidden");
        if (secAddress) secAddress.classList.remove("hidden");
        if (secFinance) secFinance.classList.add("hidden");
        if (secSteward) secSteward.classList.add("hidden");
      } else if (tab === 'FINANCE') {
        if (secGeneral) secGeneral.classList.add("hidden");
        if (secRoles) secRoles.classList.add("hidden");
        if (secAddress) secAddress.classList.add("hidden");
        if (secFinance) secFinance.classList.remove("hidden");
        if (secSteward) secSteward.classList.add("hidden");
      } else if (tab === 'STEWARD') {
        if (secGeneral) secGeneral.classList.add("hidden");
        if (secRoles) secRoles.classList.add("hidden");
        if (secAddress) secAddress.classList.add("hidden");
        if (secFinance) secFinance.classList.add("hidden");
        if (secSteward) secSteward.classList.remove("hidden");
      }
    }

    function openSubmitReasonModal() {
      var modal = document.getElementById("submitReasonModal");
      var error = document.getElementById("submitReasonError");
      if (error) error.classList.add("hidden");
      if (modal) modal.classList.remove("hidden");
    }

    function closeSubmitReasonModal() {
      var modal = document.getElementById("submitReasonModal");
      if (modal) modal.classList.add("hidden");
    }

    function confirmSubmitWithReason() {
      var reasonInput = document.getElementById("submitReasonInput");
      var reasonError = document.getElementById("submitReasonError");
      var val = reasonInput ? reasonInput.value.trim() : "";
      if (!val) {
        if (reasonError) reasonError.classList.remove("hidden");
        return;
      }
      closeSubmitReasonModal();
      submitBspAction('SUBMIT');
    }

    function closeSuccessModal() {
      var modal = document.getElementById("submitSuccessModal");
      if (modal) modal.classList.add("hidden");
    }

    function showToast(message, type) {
      type = type || "info";
      var bgClasses = {
        success: "bg-white/90 backdrop-blur-md border-l-4 border-emerald-500 text-slate-800",
        error: "bg-white/90 backdrop-blur-md border-l-4 border-rose-500 text-slate-800",
        info: "bg-white/90 backdrop-blur-md border-l-4 border-blue-500 text-slate-800"
      };
      var stack = document.getElementById("toastStack");
      if (!stack) return;

      var toast = document.createElement("div");
      toast.className = 'min-w-[280px] max-w-[380px] ' + (bgClasses[type] || bgClasses.info) + ' ' +
        'p-3 rounded-xl text-xs flex items-center gap-2 shadow-lg border border-slate-200/80 transition-all duration-300 ' +
        'opacity-100 translate-y-0 pointer-events-auto';
      toast.innerHTML = '<span class="shrink-0 font-bold">' +
        (type === 'success' ? '[OK]' : (type === 'error' ? '[ERR]' : '[INFO]')) +
        '</span><span class="font-semibold">' + message + '</span>';
      stack.appendChild(toast);

      setTimeout(function () {
        toast.classList.add("opacity-0", "translate-y-2");
        setTimeout(function () { toast.remove(); }, 300);
      }, 3500);
    }

    function exportBpSummaryToExcel() {
      if (typeof XLSX === 'undefined') {
        showToast("Excel generator engine unavailable.", "error");
        return;
      }
      var name1 = document.getElementById('formName1') ? document.getElementById('formName1').value : '';
      var tax = document.getElementById('formTaxNum') ? document.getElementById('formTaxNum').value : '';
      var city = document.getElementById('formCity') ? document.getElementById('formCity').value : '';
      var street = document.getElementById('formStreet') ? document.getElementById('formStreet').value : '';
      var bukrs = document.getElementById('formBukrs') ? document.getElementById('formBukrs').value : '';
      var akont = document.getElementById('formAkont') ? document.getElementById('formAkont').value : '';

      var rows = [
        ["Field", "Value"],
        ["Legal Name 1", name1],
        ["Tax Number / NPWP", tax],
        ["Street Address", street],
        ["City", city],
        ["Company Code", bukrs],
        ["Recon Account", akont]
      ];

      var ws = XLSX.utils.aoa_to_sheet(rows);
      var wb = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(wb, ws, "BP Summary");
      XLSX.writeFile(wb, "BP_Profile_" + Date.now().toString(36).toUpperCase() + ".xlsx");
      showToast("Data profile exported to Excel.", "success");
    }
  