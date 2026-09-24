                var fullStagingData = [];
                var selectedReqNos = [];
                var loadedBatchDetails = {};
                var loadedBatchAttachments = {};

                
                var currentMmZoom = 1;
                var mmPanX = 0;
                var mmPanY = 0;
                var isMmDragging = false;
                var startMmDragX = 0;
                var startMmDragY = 0;

                function applyMmImageTransform(animate) {
                    if (animate === undefined) animate = true;
                    var target = document.getElementById("mmImagePreviewTarget");
                    var zoomLabel = document.getElementById("mmImageZoomLevel");
                    var viewport = document.getElementById("mmImagePreviewViewport");
                    if (!target) return;

                    target.style.transition = animate ? "transform 0.15s ease-out" : "none";
                    target.style.transform = "scale(" + currentMmZoom + ") translate(" + 
                        (mmPanX / currentMmZoom) + "px, " + (mmPanY / currentMmZoom) + "px)";

                    if (zoomLabel) {
                        zoomLabel.innerText = Math.round(currentMmZoom * 100) + "%";
                    }
                    if (viewport) {
                        viewport.style.cursor = (currentMmZoom > 1) ?
                            (isMmDragging ? "grabbing" :
                            "grab") : "default";
                    }
                }

                function changeMmImageZoom(delta) {
                    var newZoom = currentMmZoom + delta;
                    newZoom = Math.min(Math.max(newZoom, 0.5), 5.0);
                    if (newZoom <= 1) { mmPanX = 0; mmPanY = 0; }
                    currentMmZoom = Math.round(newZoom * 100) / 100;
                    applyMmImageTransform(true);
                }

                function setMmImageZoom(targetZoom) {
                    currentMmZoom = Math.min(Math.max(targetZoom, 0.5), 5.0);
                    if (currentMmZoom <= 1) { mmPanX = 0; mmPanY = 0; }
                    applyMmImageTransform(true);
                }

                function resetMmImageZoom() {
                    currentMmZoom = 1;
                    mmPanX = 0;
                    mmPanY = 0;
                    applyMmImageTransform(true);
                }

                function previewMmImage(src, caption) {
                    var modal = document.getElementById("mmImagePreviewModal");
                    var target = document.getElementById("mmImagePreviewTarget");
                    var cap = document.getElementById("mmImagePreviewCaption");
                    if (!modal || !target) return;
                    target.src = src;
                    if (cap) cap.innerText = caption || "Attachment Image";
                    resetMmImageZoom();
                    modal.classList.remove("hidden");
                }

                function closeMmImagePreview() {
                    var modal = document.getElementById("mmImagePreviewModal");
                    if (modal) modal.classList.add("hidden");
                    resetMmImageZoom();
                }

                function previewMmImageByIdx(reqNo, idx) {
                    var atts = loadedBatchAttachments[reqNo] || [];
                    var att = atts[idx];
                    if (!att) return;
                    var rawB64 = att.file_base64 || '';
                    var fullB64 = rawB64;
                    if (rawB64 && !rawB64.startsWith('data:')) {
                        var mime = att.file_type || 'image/jpeg';
                        fullB64 = 'data:' + mime + ';base64,' + rawB64;
                    }
                    previewMmImage(fullB64, att.file_name || 'Attachment Image');
                }

                function initMmImageZoomEvents() {
                    var viewport = document.getElementById("mmImagePreviewViewport");
                    if (!viewport) return;

                    viewport.addEventListener("wheel", function (e) {
                        var modal = document.getElementById("mmImagePreviewModal");
                        if (modal && !modal.classList.contains("hidden")) {
                            e.preventDefault();
                            var delta = e.deltaY < 0 ? 0.25 : -0.25;
                            changeMmImageZoom(delta);
                        }
                    }, { passive: false });

                    viewport.addEventListener("mousedown", function (e) {
                        if (currentMmZoom > 1) {
                            isMmDragging = true;
                            startMmDragX = e.clientX - mmPanX;
                            startMmDragY = e.clientY - mmPanY;
                            viewport.style.cursor = "grabbing";
                            e.preventDefault();
                        }
                    });

                    window.addEventListener("mousemove", function (e) {
                        if (isMmDragging && currentMmZoom > 1) {
                            mmPanX = e.clientX - startMmDragX;
                            mmPanY = e.clientY - startMmDragY;
                            applyMmImageTransform(false);
                        }
                    });

                    window.addEventListener("mouseup", function () {
                        if (isMmDragging) {
                            isMmDragging = false;
                            var vp = document.getElementById("mmImagePreviewViewport");
                            if (vp) vp.style.cursor = (currentMmZoom > 1) ? "grab" : "default";
                        }
                    });

                    viewport.addEventListener("dblclick", function (e) {
                        e.preventDefault();
                        if (currentMmZoom === 1) {
                            changeMmImageZoom(1.0);
                        } else {
                            resetMmImageZoom();
                        }
                    });
                }

                document.addEventListener("click", function (e) {
                    var card = e.target.closest('[data-action="open-mm-preview"]');
                    if (card) {
                        var img = card.querySelector("img");
                        var src = card.getAttribute("data-src") || (img ? img.src : "");
                        var caption = card.getAttribute("data-caption") || "Attachment Image";
                        if (src) {
                            previewMmImage(src, caption);
                        } else {
                            var reqNo = card.getAttribute("data-req-no");
                            var idx = parseInt(card.getAttribute("data-idx"), 10);
                            if (reqNo && !isNaN(idx)) {
                                previewMmImageByIdx(reqNo, idx);
                            }
                        }
                    }
                });

                document.addEventListener("keydown", function (e) {
                    var modal = document.getElementById("mmImagePreviewModal");
                    if (modal && !modal.classList.contains("hidden")) {
                        if (e.key === "Escape") {
                            closeMmImagePreview();
                            e.stopPropagation();
                        } else if (e.key === "+" || e.key === "=") {
                            changeMmImageZoom(0.25);
                            e.stopPropagation();
                        } else if (e.key === "-") {
                            changeMmImageZoom(-0.25);
                            e.stopPropagation();
                        }
                    }
                });

                document.addEventListener("DOMContentLoaded", function () {
                    initMmImageZoomEvents();
                    var nameLabel = document.getElementById("userNameLabel");
                    if (nameLabel && nameLabel.innerText.trim()) {
                        var initial = nameLabel.innerText.trim().charAt(0).toUpperCase();
                        var avatar = document.getElementById("userAvatarInitial");
                        if (avatar) avatar.innerText = initial;
                    }
                    loadStagingList();
                });

                function loadStagingList() {
                    var tbody = document.getElementById("stagingTableBody");
                    if (tbody) {
                        tbody.innerHTML = '<tr><td colspan="7" class="p-8 text-center text-slate-400 italic"' +
                            '>Loading request queue...</td></tr>';
                    }
                    selectedReqNos = [];
                    loadedBatchDetails = {};
                    loadedBatchAttachments = {};
                    updateBatchActionBar();

                    fetch("?action=GET_STAGING_LIST", { method: "POST" })
                        .then(function (res) {
                            if (!res.ok) {
                                throw new Error("HTTP error status: " + res.status);
                            }
                            return res.json();
                        })
                        .then(function (data) {
                            fullStagingData = data || [];
                            updateKPICards(fullStagingData);
                            applyFilter();
                        })
                        .catch(function (err) {
                            console.error("Detail Error AJAX:", err);
                            if (tbody) {
                                tbody.innerHTML = '<tr><td colspan="7" class="p-8 text-center text-ro' +
    'se-500 italic">Failed to load data: ' + 
                                    
                                    
                                    err.message + '</td></tr>';
                            }
                        });

                    fetch("?OnInputProcessing=GET_COUNTERS&action=GET_COUNTERS", { method: "POST" })
                        .then(function (res) { return res.json(); })
                        .then(function (cnts) {
                            if (!cnts) return;
                            var elApproved = document.getElementById("statApprovedCount");
                            if (elApproved && 
                                cnts.approved !== undefined) elApproved.innerText = cnts.approved;
                            var elRejected = document.getElementById("statRejectedCount");
                            if (elRejected && 
                                cnts.rejected !== undefined) elRejected.innerText = cnts.rejected;
                            var elDraft = document.getElementById("statDraftCount");
                            if (elDraft && cnts.draft !== undefined) elDraft.innerText = cnts.draft;
                            if (typeof loadSidebarCounters === "function") loadSidebarCounters();
                        })
                        .catch(function (e) {});
                }

                function updateKPICards(data) {
                    var total = data.length;
                    var draft = data.filter(function (i) { return i.status === 'DRAFT'; }).length;
                    var submitted = data.filter(function (i) { return i.status === 'SUBMITTED' || 
                        i.status === 'CHECKED' || i.status === 'CODED'; }).length;
                    var approved = data.filter(function (i) { return i.status === 'APPROVED'; }).length;
                    var failed = data.filter(function (i) { return i.status === 'FAILED'; }).length;
                    var rejected = data.filter(function (i) { return i.status === 'REJECTED'; }).length;

                    var elPending = document.getElementById("statPendingCount");
                    if (elPending) elPending.innerText = (submitted + draft);

                    var elApproved = document.getElementById("statApprovedCount");
                    if (elApproved && approved > 0) elApproved.innerText = approved;

                    var elRejected = document.getElementById("statRejectedCount");
                    if (elRejected && (rejected + failed) > 0) elRejected.innerText = (rejected + failed);

                    var elDraft = document.getElementById("statDraftCount");
                    if (elDraft) elDraft.innerText = draft;

                    // Dynamic SAP Data updates for Overview Badges / Tiles
                    var elMatCount = document.getElementById("badgeMatCount");
                    if (elMatCount) {
                        elMatCount.innerText = total.toLocaleString('en-US');
                    }

                    var elBpCount = document.getElementById("badgeBpCount");
                    if (elBpCount) {
                        elBpCount.innerText = approved.toLocaleString('en-US');
                    }

                    var elFinCount = document.getElementById("badgeFinCount");
                    if (elFinCount) {
                        elFinCount.innerText = (submitted + draft).toLocaleString('en-US');
                    }

                    var elTotalEnt = document.getElementById("badgeTotalEntCount");
                    if (elTotalEnt) {
                        elTotalEnt.innerText = total.toLocaleString('en-US');
                    }
                }

                function toggleDateSort() {
                    var input = document.getElementById("dateSortFilter");
                    if (!input) return;
                    var newSort = (input.value === "DESC") ? "ASC" : "DESC";
                    setDateSort(newSort);
                }

                function setDateSort(val) {
                    var input = document.getElementById("dateSortFilter");
                    var label = document.getElementById("dateSortLabel");
                    var icon = document.getElementById("dateSortIcon");

                    if (input) input.value = val;
                    if (label) {
                        label.innerHTML = (val === "ASC") ?
                            "Terlama &rarr; Terbaru" :
                            "Terbaru &rarr; Terlama";
                    }
                    if (icon) {
                        icon.style.transform = (val === "ASC") ? "rotate(180deg)" : "rotate(0deg)";
                    }
                    applyFilter();
                }

                function filterByStatus(status) {
                    var statusFilter = document.getElementById("statusFilter");
                    if (statusFilter) statusFilter.value = status;
                    applyFilter();
                }

                function applyFilter() {
                    var searchInput = document.getElementById("searchInput");
                    var statusFilter = document.getElementById("statusFilter");
                    var columnFilter = document.getElementById("columnFilter");
                    var dateSortFilter = document.getElementById("dateSortFilter");

                    var search = (searchInput ? searchInput.value : '').toLowerCase();
                    var status = statusFilter ? statusFilter.value : 'ALL';
                    var column = columnFilter ? columnFilter.value : 'ALL';
                    var dateSort = dateSortFilter ? dateSortFilter.value : 'DESC';

                    var filtered = fullStagingData.filter(function (item) {
                        var matchSearch = false;
                        if (column === 'ALL') {
                            matchSearch = (item.req_no || '').toLowerCase().indexOf(search) >= 0 ||
                                (item.remarks || '').toLowerCase().indexOf(search) >= 0 ||
                                (item.sub_reason || '').toLowerCase().indexOf(search) >= 0 ||
                                (item.requestor || '').toLowerCase().indexOf(search) >= 0 ||
                                (item.rej_reason || '').toLowerCase().indexOf(search) >= 0;
                        } else {
                            matchSearch = (item[column] || '').toLowerCase().indexOf(search) >= 0;
                        }
                        var matchStatus = (status === 'ALL') || (item.status === status);
                        return matchSearch && matchStatus;
                    });

                    filtered.sort(function (a, b) {
                        var dateA = (a.req_date || '') + (a.req_time || '');
                        var dateB = (b.req_date || '') + (b.req_time || '');

                        if (dateSort === 'ASC') {
                            return dateA.localeCompare(dateB);
                        } else {
                            return dateB.localeCompare(dateA);
                        }
                    });

                    renderTable(filtered);
                }

                function escapeHtml(str) {
                    if (str === null || str === undefined) return '';
                    return String(str)
                        .replace(/&/g, "&amp;")
                        .replace(/</g, "&lt;")
                        .replace(/>/g, "&gt;")
                        .replace(/\x22/g, "&quot;")
                        .replace(/\x27/g, "&#039;")
                        .replace(/[\r\n]+/g, " ");
                }

                function renderTable(data) {
                    var tbody = document.getElementById("stagingTableBody");
                    if (!tbody) return;
                    tbody.innerHTML = "";

                    var masterCheck = document.getElementById("selectAllCheckbox");
                    if (masterCheck) masterCheck.checked = false;

                    if (!data || data.length === 0) {
                        tbody.innerHTML = '<tr><td colspan="7" class="p-8 text-center text-slate-400 italic"' +
                            '>No records found.</td></tr>';
                        return;
                    }

                    data.forEach(function (item, idx) {
                        var tr = document.createElement("tr");
                        tr.className = "hover:bg-slate-50/80 transition-colors border-b border-slate-100";

                        var reqNoEsc = escapeHtml(item.req_no);
                        var rawSub = item.sub_reason || (item.remarks && 
                            item.remarks.indexOf('.') === -1 ? item.remarks : '') || 
                                'Permintaan Material Master';
                        var subReasonEsc = escapeHtml(rawSub);
                        var filenameEsc = escapeHtml(item.remarks || '');
                        var fname = (item.first_name || item.firstname || '').trim();
                        var lname = (item.last_name || item.lastname || '').trim();
                        var fullReqName = '';
                        if (fname || lname) {
                            fullReqName = (fname + (lname ? ' ' + lname : '')).trim();
                        } else {
                            fullReqName = (item.requestor_name || item.requestor || '-').trim();
                        }
                        var requestorEsc = escapeHtml(fullReqName);
                        var rejReasonEsc = escapeHtml(item.rej_reason);

                        var fDate = "-";
                        if (item.req_date && item.req_date.length === 8) {
                            fDate = item.req_date.substring(6, 8) + '/' + 
                                item.req_date.substring(4, 6) + '/' + 
                                
                                item.req_date.substring(0, 4);
                        } else if (item.req_date) {
                            fDate = escapeHtml(item.req_date);
                        }
                        var fTime = (item.req_time && item.req_time.length >= 4) ? (item.req_time.substring(0, 2) + 
                            
                            
                            ':' + item.req_time.substring(2, 4)) : "";
                        var dateTimeStr = fDate + (fTime ? ' ' + fTime : '');

                        var badge = '<span class="inline-flex items-center gap-1.5 bg-s' +
    'late-100 text-slate-700 text-[10px] font-extrabold' +
    ' px-2.5 py-0.5 rounded-full border border-slate-20' +
    '0">DRAFT</span>';

                        if (item.status === 'SUBMITTED' || item.status === 'CHECKED' || 
                            item.status === 'CODED') {
                            badge = '<span class="inline-flex items-center gap-1.5 bg-sky-50 text-sky-' +
                                '700 text-[10px] font-extrabold px-2.5 py-0.5 rounded-full border ' +
                                'border-sky-200">';
                            badge += '<span class="w-1.5 h-1.5 rounded-full bg-sky-500 animate-pulse"><' +
                                '/span> Ready</span>';
                        }

                        if (item.status === 'VALIDATING' || item.status === 'UPLOADING') {
                            badge = '<span class="inline-flex items-center gap-1.5 bg-amber-50 text-am' +
                                'ber-800 text-[10px] font-extrabold px-2.5 py-0.5 rounded-full bor' +
                                'der border-amber-200 animate-pulse">';
                            badge += '<span class="w-1.5 h-1.5 rounded-full bg-amber-500"></span> UPLOA' +
                                'DING SAP...</span>';
                        }

                        if (item.status === 'APPROVED') {
                            badge = '<span class="inline-flex items-center gap-1.5 bg-emerald-50 text-' +
                                'emerald-700 text-[10px] font-extrabold px-2.5 py-0.5 rounded-full' +
                                ' border border-emerald-200">';
                            badge += '<span class="w-1.5 h-1.5 rounded-full bg-emerald-500"></span> APP' +
                                'ROVED (SAP)</span>';
                        }

                        if (item.status === 'FAILED') {
                            badge = '<span class="inline-flex items-center gap-1.5 bg-rose-50 text-ros' +
                                'e-700 text-[10px] font-extrabold px-2.5 py-0.5 rounded-full borde' +
                                'r border-rose-200">';
                            badge += '<span class="w-1.5 h-1.5 rounded-full bg-rose-500"></span> GAGAL ' +
                                'SAP</span>';
                        }

                        if (item.status === 'REJECTED') {
                            badge = '<span class="inline-flex items-center gap-1.5 bg-rose-50 text-ros' +
                                'e-700 text-[10px] font-extrabold px-2.5 py-0.5 rounded-full borde' +
                                'r border-rose-200">';
                            badge += '<span class="w-1.5 h-1.5 rounded-full bg-rose-500"></span> REJECT' +
                                'ED</span>';
                        }

                        var reasonHtml = '';
                        if (item.status === 'REJECTED' && rejReasonEsc) {
                            reasonHtml = '<div class="text-[11px] text-rose-800 font-medium mt-1.5 bg-rose-' +
                                '50 p-2 rounded-xl border border-rose-200">';
                            reasonHtml += '<strong class="font-extrabold">Reason:</strong> ' + rejReasonEsc + 
                                '</div>';
                        } else if (item.status === 'FAILED' && rejReasonEsc) {
                            reasonHtml = '<div class="text-[11px] text-rose-800 font-medium mt-1.5 bg-rose-' +
                                '50 p-2 rounded-xl border border-rose-200">';
                            reasonHtml += '<strong class="font-extrabold">SAP Error:</strong> ' + 
                                rejReasonEsc + 
                                
                                '</div>';
                        }

                        var actionBtns = '';
                        if (item.status === 'SUBMITTED' || item.status === 'CHECKED' || 
                            item.status === 'CODED' || item.status === 'FAILED') {
                            var approveLabel = item.status === 'FAILED' ? 'Retry' : 'Approve';

                            actionBtns += '<button type="button" id="btn_approve_' + reqNoEsc + '" ';
                            actionBtns += 'onclick="quickApproveRow(\'' + reqNoEsc + '\')" ';
                            actionBtns += 'class="bg-emerald-600 hover:bg-emerald-700 text-white ';
                            actionBtns += 'text-[11px] font-extrabold px-3 py-1 rounded-full ';
                            actionBtns += 'shadow-2xs transition cursor-pointer flex items-center gap-1">';
                            actionBtns += approveLabel + '</button>';

                            actionBtns += '<button type="button" onclick="openRejectModal(\'SINGLE\', \'' + 
                                reqNoEsc + '\')" ';
                            actionBtns += 'class="bg-rose-50 hover:bg-rose-100 text-rose-700 border ';
                            actionBtns += 'border-rose-200 text-[11px] font-extrabold px-3 py-1 rounded-full' +
                                ' ';
                            actionBtns += 'shadow-2xs transition cursor-pointer flex items-center gap-1">Rej' +
                                'ect</button>';
                        }

                        if (item.status === 'DRAFT') {
                            actionBtns += '<button type="button" onclick="deleteDraft(\'' + reqNoEsc + 
                                '\')" ';
                            actionBtns += 'class="bg-rose-50 hover:bg-rose-100 text-rose-700 border ';
                            actionBtns += 'border-rose-200 text-[11px] font-extrabold px-3 py-1 rounded-full' +
                                ' ';
                            actionBtns += 'shadow-2xs transition cursor-pointer flex items-center gap-1">Del' +
                                'ete</button>';
                        }

                        var canApprove = (item.status === 'SUBMITTED' || item.status === 'CHECKED' || 
                            item.status === 'CODED' || item.status === 'FAILED');
                        var isChecked = canApprove && (selectedReqNos.indexOf(item.req_no) >= 0);

                        var htmlStr = '';
                        // 1. Checkbox
                        htmlStr += '<td class="p-3.5 text-center">';
                        if (canApprove) {
                            htmlStr += '<input type="checkbox" value="' + reqNoEsc + '" ';
                            htmlStr += (isChecked ? 'checked ' : '') + ' ';
                            htmlStr += 'onchange="toggleSelectRow(this)" ';
                            htmlStr += 'class="row-checkbox w-3.5 h-3.5 rounded ';
                            htmlStr += 'border-slate-300 text-emerald-600 focus:ring-emerald-500 ';
                            htmlStr += 'cursor-pointer">';
                        } else {
                            htmlStr += '<input type="checkbox" disabled class="w-3.5 h-3.5 rounded ';
                            htmlStr += 'border-slate-200 text-slate-300 cursor-not-allowed opacity-40" ';
                            htmlStr += 'title="Request already processed">';
                        }
                        htmlStr += '</td>';

                        // 2. Detail
                        htmlStr += '<td class="p-3.5 text-center">';
                        htmlStr += '<button type="button" onclick="toggleExpandRow(\'' + reqNoEsc + '\')" ';
                        htmlStr += 'id="expand_btn_' + reqNoEsc + '" ';
                        htmlStr += 'class="w-7 h-7 rounded-full bg-slate-100 hover:bg-emerald-100 ';
                        htmlStr += 'text-slate-700 hover:text-emerald-800 font-extrabold flex items-center ';
                        htmlStr += 'justify-center transition shadow-2xs text-[10px] cursor-pointer">' +
                            '&#9660;</button>';
                        htmlStr += '</td>';

                        // 3. Permintaan / Sub Reason
                        htmlStr += '<td class="p-3.5 font-medium text-slate-800 max-w-[340px]">';
                        htmlStr += '<div class="font-extrabold text-slate-900 text-xs leading-snug">' + 
                            subReasonEsc + '</div>';
                        if (filenameEsc) {
                            htmlStr += '<div class="flex items-center gap-2 mt-1 flex-wrap">';
                            htmlStr += '<span class="text-[10px] text-slate-500 font-semib' +
    'old bg-slate-100 px-1.5 py-0.5 rounded border bord' +
    'er-slate-200" title="File Name">File: ' + 
                                
                                
                                filenameEsc + '</span>';
                            htmlStr += '</div>';
                        }
                        htmlStr += reasonHtml + '</td>';

                        // 4. Request Date
                        htmlStr += '<td class="p-3.5 text-center font-mono text-slate-600 text-[11px]">' + 
                            dateTimeStr + '</td>';

                        // 5. Requestor
                        htmlStr += '<td class="p-3.5 text-center font-extrabold text-emerald-800 font-mono">' + 
                            
                            
                            (requestorEsc || '-') + '</td>';

                        // 6. Status
                        htmlStr += '<td class="p-3.5 text-center">' + badge + '</td>';

                        // 7. Actions
                        htmlStr += '<td class="p-3.5 text-center"><div class="flex ite' +
    'ms-center justify-center gap-1.5 flex-wrap">' + 
                            
                            
                            (actionBtns || '-') + '</div></td>';

                        tr.innerHTML = htmlStr;
                        tbody.appendChild(tr);

                        var expandTr = document.createElement("tr");
                        expandTr.id = "expand_row_" + reqNoEsc;
                        expandTr.className = "hidden bg-slate-50/90 border-b border-slate-200";

                        var expStr = '';
                        expStr += '<td colspan="7" class="p-3 max-w-0">';
                        expStr += '<div class="p-4 bg-slate-100/90 border border-slate-200 ';
                        expStr += 'rounded-xl shadow-inner w-full max-w-full overflow-hidden">';
                        expStr += '<div class="flex flex-col sm:flex-row sm:items-center ';
                        expStr += 'justify-between gap-2 mb-2.5 px-1">';
                        expStr += '<div class="flex flex-wrap items-center gap-2">';
                        expStr += '<span class="text-[11px] font-bold text-slate-800 ' +
    'uppercase tracking-wider">Batch Items (ID: <span c' +
    'lass="font-mono text-emerald-800">' + 
                            
                            
                            reqNoEsc + '</span>)</span>';
                        expStr += '<span class="text-[10px] font-semibold text-slate-' +
    '600 bg-white px-2 py-0.5 rounded border border-sla' +
    'te-200 shadow-xs">' + 
                            
                            
                            (item.total_item || 0) + ' items</span>';
                        expStr += '</div>';
                        expStr += '<div class="flex items-center gap-2">';
                        expStr += '<input type="text" id="detailSearch_' + reqNoEsc + '" ';
                        expStr += 'onkeyup="filterDetailRows(\'' + reqNoEsc + '\')" ';
                        expStr += 'placeholder="Search batch items..." ';
                        expStr += 'class="px-2.5 py-1 text-[11px] border border-slate-300 rounded-lg ';
                        expStr += 'bg-white outline-none focus:border-emerald-600 focus:ring-1 ';
                        expStr += 'focus:ring-emerald-500 w-56 shadow-xs transition">';
                        expStr += '</div></div>';
                        expStr += '<div id="expand_content_' + reqNoEsc + '" ';
                        expStr += 'class="min-h-[60px] flex items-center justify-center">';
                        expStr += '<div class="animate-pulse text-slate-400 text-xs font-medium">Loa' +
                            'ding batch details...</div>';
                        expStr += '</div>';
                        expStr += '</div></div></td>';

                        expandTr.innerHTML = expStr;
                        tbody.appendChild(expandTr);
                    });
                }

                function toggleExpandRow(reqNo) {
                    var expandTr = document.getElementById("expand_row_" + reqNo);
                    var expandBtn = document.getElementById("expand_btn_" + reqNo);
                    if (!expandTr) return;

                    var isHidden = expandTr.classList.contains("hidden");

                    if (isHidden) {
                        expandTr.classList.remove("hidden");
                        if (expandBtn) {
                            expandBtn.innerHTML = "&#9650;";
                            expandBtn.className = "w-6 h-6 rounded-full bg-emerald-700 text-white font-bold " +
                                "flex items-center justify-center transition shadow-xs text-[10px]";
                        }
                        if (!loadedBatchDetails[reqNo]) {
                            fetchBatchDetail(reqNo);
                        }
                    } else {
                        expandTr.classList.add("hidden");
                        if (expandBtn) {
                            expandBtn.innerHTML = "&#9660;";
                            expandBtn.className = "w-6 h-6 rounded-full bg-slate-100 hover:bg-emerald-100 " +
                                "text-slate-700 hover:text-emerald-800 font-bold flex items-center " +
                                "justify-center transition shadow-xs text-[10px]";
                        }
                    }
                }

                function fetchBatchDetail(reqNo) {
                    var container = document.getElementById("expand_content_" + reqNo);
                    if (!container) return;

                    var formData = new FormData();
                    formData.append("REQ_NO", reqNo);

                    fetch("?action=GET_UPLOAD_DETAIL", { method: "POST", body: formData })
                        .then(function (res) { return res.json(); })
                        .then(function (resp) {
                            var items = [];
                            var atts = [];
                            if (Array.isArray(resp)) {
                                items = resp;
                            } else if (resp && typeof resp === 'object') {
                                items = resp.items || resp.details || resp.data || [];
                                atts = resp.attachments || resp.files || [];
                            }
                            loadedBatchDetails[reqNo] = items;
                            loadedBatchAttachments[reqNo] = atts;
                            renderDetailRows(reqNo, items, atts);
                        })
                        .catch(function (err) {
                            container.innerHTML = '<div class="p-4 text-center text-rose-500 text-xs"' +
    '>Failed to load detail: ' + 
                                
                                
                                escapeHtml(err.message) + '</div>';
                        });
                }

                function filterDetailRows(reqNo) {
                    var input = document.getElementById("detailSearch_" + reqNo);
                    var searchVal = (input ? input.value : '').toLowerCase();
                    var list = loadedBatchDetails[reqNo] || [];

                    var filtered = list.filter(function (row) {
                        return (row.matnr_ext || '').toLowerCase().indexOf(searchVal) >= 0 ||
                            (row.maktx || '').toLowerCase().indexOf(searchVal) >= 0 ||
                            (row.mtart || '').toLowerCase().indexOf(searchVal) >= 0 ||
                            (row.matkl || '').toLowerCase().indexOf(searchVal) >= 0 ||
                            (row.meins || '').toLowerCase().indexOf(searchVal) >= 0 ||
                            (row.werks || '').toLowerCase().indexOf(searchVal) >= 0 ||
                            (row.lgort || '').toLowerCase().indexOf(searchVal) >= 0;
                    });

                    renderDetailRows(reqNo, filtered);
                }

                                                                function renderDetailRows(reqNo, list,
                                                                     attachments) {
                    var container = document.getElementById("expand_content_" + reqNo);
                    if (!container) return;

                    var reqNoEsc = escapeHtml(reqNo);
                    if (!attachments) attachments = loadedBatchAttachments[reqNo] || [];

                    var html = '';

                    // 1. ATTACHMENT GALLERY SECTION (DataForge Audit Screenshot Style)
                    if (attachments && attachments.length > 0) {
                        html += '<div class="p-5 bg-slate-50/60 border border-slate-200/80 ';
                        html += 'rounded-xl mb-4 space-y-3">';
                        html += '<div class="flex items-center justify-between px-1">';
                        html += '  <span class="text-[11px] font-extrabold text-slate-400 ';
                        html += 'uppercase tracking-wider">Lampiran & Gambar (' + attachments.length + 
                            ' File)</span>';
                        html += '  <span class="text-[11px] font-semibold text-slate-400 ';
                        html += 'flex items-center gap-1.5"><svg class="w-3.5 h-3.5 text-emerald-500" ';
                        html += 'fill="none" stroke="currentColor" viewBox="0 0 24 24">';
                        html += '<path stroke-linecap="round" stroke-linejoin="round" ';
                        html += 'stroke-width="2.5" d="M5 13l4 4L19 7"/></svg> ';
                        html += 'Verified attachments</span>';
                        html += '</div>';

                        html += '<div class="flex items-center gap-4 overflow-x-auto pb-2">';
                        attachments.forEach(function (att, idx) {
                            var rawB64 = att.file_base64 || '';
                            var fullB64 = rawB64;
                            if (rawB64 && !rawB64.startsWith('data:')) {
                                var mime = att.file_type || 'image/png';
                                fullB64 = 'data:' + mime + ';base64,' + rawB64;
                            }
                            var isImg = (att.file_type && 
                                att.file_type.toLowerCase().indexOf('image') !== -1) ||
                                       fullB64.startsWith('data:image') ||
                                       /\.(jpg|jpeg|png|webp|gif|bmp)$/i.test(att.file_name || '');
                            var fileName = escapeHtml(att.file_name || ('File ' + (idx + 1)));
                            var captionName = att.file_name ?
                                att.file_name.replace(/\.[^/.]+$/, '') :
                                ('Attachment ' + 
                                
                                
                                (idx + 1));
                            var caption = 'File ' + (idx + 1) + ': ' + captionName;

                            html += '<div class="bg-white border border-slate-200/90 ';
                            html += 'rounded-xl p-2.5 w-52 shrink-0 flex flex-col ';
                            html += 'items-center justify-between text-center shadow-2xs ';
                            html += 'hover:shadow-md transition-all cursor-pointer group relative" ';
                            html += '     data-action="open-mm-preview" ';
                            html += 'data-src="' + fullB64 + '" ';
                            html += 'data-caption="' + escapeHtml(caption) + '" ';
                            html += 'data-req-no="' + reqNoEsc + '" ';
                            html += 'data-idx="' + idx + '">';

                            html += '  <div class="h-32 w-full rounded-lg overflow-hidden ';
                            html += 'bg-slate-100 flex items-center justify-center border ';
                            html += 'border-slate-100 relative">';
                            if (isImg && fullB64) {
                                html += '    <img src="' + fullB64 + '" alt="' + fileName + '" ';
                                html += 'class="w-full h-full object-contain transition ';
                                html += 'transform group-hover:scale-105 p-1">';
                                html += '    <div class="absolute inset-0 bg-slate-950/40 opacity-0 ';
                                html += 'group-hover:opacity-100 transition-opacity flex items-center ';
                                html += 'justify-center gap-1.5 text-white font-bold text-xs rounded-lg ba' +
                                    'ckdrop-blur-2xs">';
                                html += '      <svg class="w-4 h-4" fill="none" stroke="currentColor" view' +
                                    'Box="0 0 24 24">';
                                html += '        <path stroke-linecap="round" stroke-linejoin="round" stro' +
                                    'ke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>';
                                html += '        <path stroke-linecap="round" stroke-linejoin="round" stro' +
                                    'ke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 ' +
                                    '2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.5' +
                                    '42-7z"/>';
                                html += '      </svg>';
                                html += '      <span>Preview</span></div>';
                            } else {
                                html += '    <div class="w-full h-full bg-slate-50 ';
                                html += 'flex flex-col items-center justify-center p-2">';
                                html += '      <span class="text-2xl">&#128196;</span>';
                                html += '    </div>';
                            }
                            html += '  </div>';

                            html += '  <div class="w-full flex items-center justify-between mt-2 gap-1">';
                            html += '    <p class="text-[11px] font-bold text-slate-700 ';
                            html += 'truncate max-w-[130px]" title="' + fileName + '">' + caption + '</p>';
                            if (isImg) {
                                html += '    <button type="button" class="text-[10px] font-bold text-emera' +
                                    'ld-600 ';
                                html += 'hover:text-emerald-700 bg-emerald-50 hover:bg-emerald-100 ';
                                html += 'px-1.5 py-0.5 rounded border border-emerald-200 shrink-0">👁 View<' +
                                    '/button>';
                            }
                            html += '  </div>';
                            html += '</div>';
                        });
                        html += '</div></div>';
                    }

                    // 2. MATERIAL ITEMS TABLE (DataForge Audit Screenshot Table Style)
                    if (!list || list.length === 0) {
                        html += '<div class="p-4 text-center text-slate-400 italic text-xs">No ite' +
                            'ms in this batch.</div>';
                    } else {
                        html += '<div class="border border-slate-200/90 rounded-xl ';
                        html += 'overflow-hidden bg-white shadow-2xs mb-3">';
                        html += '<table class="w-full text-[11px] border-collapse min-w-[700px]">';
                        html += '<thead><tr class="bg-slate-50 text-slate-400 font-extrabold ';
                        html += 'uppercase tracking-wider text-[10px] border-b ';
                        html += 'border-slate-200/80">';
                        html += '<th class="p-3 text-center" style="width:45px;">NO</th>';
                        html += '<th class="p-3 text-left">MATERIAL CODE</th>';
                        html += '<th class="p-3 text-left">MATERIAL DESCRIPTION</th>';
                        html += '<th class="p-3 text-center">TYPE</th>';
                        html += '<th class="p-3 text-center">GROUP</th>';
                        html += '<th class="p-3 text-center">UOM</th>';
                        html += '<th class="p-3 text-center">PLANT</th>';
                        html += '<th class="p-3 text-center">S.LO</th>';
                        html += '</tr></thead><tbody class="divide-y divide-slate-100">';

                        list.forEach(function (r, idx) {
                            var itemNo = r.item_no || (idx + 1);
                            var rawCode = r.matnr_ext || '';
                            var matCodeBadge = '<span class="px-2 py-0.5 rounded ' +
                                'bg-slate-100 text-slate-500 font-mono text-[10px] ' +
                                'font-bold">N/A</span>';
                            if (rawCode && rawCode !== '-' && rawCode !== 'N/A') {
                                matCodeBadge = '<span class="font-bold text-emerald-800">' +
                                    escapeHtml(rawCode) + '</span>';
                            }

                            html += '<tr class="hover:bg-slate-50/80 transition-colors">';
                            html += '<td class="p-3 text-center font-mono text-slate-500 font-semibold">' + 
                                itemNo + '</td>';
                            html += '<td class="p-3 font-mono font-bold text-emerald-800">' + matCodeBadge + 
                                '</td>';
                            html += '<td class="p-3 font-bold text-slate-900 text-xs">' + 
                                escapeHtml(r.maktx || '-') + '</td>';
                            html += '<td class="p-3 text-center font-mono font-semibold text-slate-600">' + 
                                escapeHtml(r.mtart || '-') + '</td>';
                            html += '<td class="p-3 text-center font-mono font-semibold text-slate-600">' + 
                                escapeHtml(r.matkl || '-') + '</td>';
                            html += '<td class="p-3 text-center font-mono font-semibold text-slate-600">' + 
                                escapeHtml(r.meins || 'PC') + '</td>';
                            html += '<td class="p-3 text-center font-mono font-semibold text-slate-600">' + 
                                escapeHtml(r.werks || '-') + '</td>';
                            html += '<td class="p-3 text-center font-mono font-semibold text-slate-600">' + 
                                escapeHtml(r.lgort || '-') + '</td>';
                            html += '</tr>';
                        });

                        html += '</tbody></table></div>';
                    }

                    container.innerHTML = html;
                }

                function toggleSelectAll(masterEl) {
                    var checkboxes = document.querySelectorAll(".row-checkbox");
                    selectedReqNos = [];

                    checkboxes.forEach(function (cb) {
                        cb.checked = masterEl.checked;
                        if (cb.checked) {
                            selectedReqNos.push(cb.value);
                        }
                    });

                    updateBatchActionBar();
                }

                function toggleSelectRow(cbEl) {
                    var reqNo = cbEl.value;
                    var idx = selectedReqNos.indexOf(reqNo);

                    if (cbEl.checked) {
                        if (idx === -1) selectedReqNos.push(reqNo);
                    } else {
                        if (idx >= 0) selectedReqNos.splice(idx, 1);
                    }

                    var masterEl = document.getElementById("selectAllCheckbox");
                    var allCheckboxes = document.querySelectorAll(".row-checkbox");
                    if (masterEl && allCheckboxes.length > 0) {
                        var allChecked = true;
                        allCheckboxes.forEach(function (cb) { if (!cb.checked) allChecked = false; });
                        masterEl.checked = allChecked;
                    }

                    updateBatchActionBar();
                }

                function updateBatchActionBar() {
                    var bar = document.getElementById("batchActionBar");
                    var badge = document.getElementById("selectedCountBadge");
                    if (!bar || !badge) return;

                    badge.innerText = selectedReqNos.length;
                    if (selectedReqNos.length > 0) {
                        bar.classList.remove("hidden");
                    } else {
                        bar.classList.add("hidden");
                    }
                }

                function quickApprove(reqNo) {
                    openApproveConfirm('SINGLE', reqNo);
                }

                function quickApproveRow(reqNo) {
                    openApproveConfirm('SINGLE', reqNo);
                }

                function triggerBulkApprove() {
                    if (selectedReqNos.length === 0) {
                        showToast("Please select at least 1 request.", "error");
                        return;
                    }
                    openApproveConfirm('BULK');
                }

                var pendingApprovalData = { mode: 'SINGLE', reqNo: '', reqNos: [] };
                var isApprovingInProgress = false;

                function openApproveConfirm(mode, singleReqNo) {
                    if (isApprovingInProgress) return;

                    var docList = [];
                    if (mode === 'SINGLE') {
                        docList = [singleReqNo];
                    } else {
                        docList = selectedReqNos.slice();
                    }

                    if (docList.length === 0) {
                        showToast("Tidak ada request yang dipilih untuk approval.", "error");
                        return;
                    }

                    pendingApprovalData.mode = mode;
                    pendingApprovalData.reqNo = singleReqNo || '';
                    pendingApprovalData.reqNos = docList;

                    var docListEl = document.getElementById("confirmApproveDocList");
                    if (docListEl) {
                        docListEl.innerText = docList.join(", ");
                    }

                    var modal = document.getElementById("approveConfirmModal");
                    if (modal) modal.classList.remove("hidden");
                }

                function cancelApproveConfirm() {
                    if (isApprovingInProgress) return;
                    var modal = document.getElementById("approveConfirmModal");
                    if (modal) modal.classList.add("hidden");
                }

                function executeConfirmedApprove() {
                    if (isApprovingInProgress) return;
                    isApprovingInProgress = true;

                    var mode = pendingApprovalData.mode;
                    var targetReqNo = pendingApprovalData.reqNo;
                    var targetReqNos = pendingApprovalData.reqNos;
                    var targetDocsStr = targetReqNos.join(', ');

                    setApproveLoadingState(true, targetReqNos);

                    var formData = new FormData();
                    var endpointAction = "";

                    if (mode === 'SINGLE') {
                        endpointAction = "?action=QUICK_APPROVE";
                        formData.append("REQ_NO", targetReqNo);
                    } else {
                        endpointAction = "?action=BULK_APPROVE";
                        formData.append("REQ_NOS", targetReqNos.join(','));
                    }

                    fetch(endpointAction, { method: "POST", body: formData })
                        .then(function (res) {
                            if (!res.ok) {
                                throw new Error("HTTP Error Status: " + res.status);
                            }
                            return res.json();
                        })
                        .then(function (data) {
                            if (data && (data.status === "SUCCESS" || data.status === "PARTIAL")) {
                                var isPartial = (data.status === "PARTIAL");
                                var successTitle = isPartial ?
                                    "MASS APPROVAL SEBAGIAN SELESAI (PARTIAL)" :
                                    "MASS APPROVAL BERHASIL & TERUPLOAD KE SAP S/4HANA";
                                var rawMsg = data.message || ("Request " + targetDocsStr + 
                                    " telah BERHASIL divalidasi dan TERUPLOAD ke SAP S/4HANA Master Data!");
                                var successMsg = formatCleanMaterialMsg(rawMsg);
                                var displayDetails = formatCleanMaterialMsg(data.message || "");
                                showToast(successMsg, isPartial ? "info" : "success");
                                showPageApprovalAlert(!isPartial, successTitle, successMsg, displayDetails);
                                showUploadResultNotification(!isPartial, successTitle, successMsg,
                                     displayDetails);
                            } else {
                                var errorMsg = (data && 
                                    data.message) ?
                                        data.message :
                                        "Approval failed without details from server.";
                                var failTitle = "APPROVE GAGAL - SAP UPLOAD ERROR";
                                var failMsg = "Proses Upload Material Request " + targetDocsStr + 
                                    " ke SAP S/4HANA GAGAL.";
                                showToast("Approval gagal untuk " + targetDocsStr, "error");
                                showPageApprovalAlert(false, failTitle, failMsg, errorMsg);
                                showUploadResultNotification(false, "Approve Failed", failMsg, errorMsg);
                            }
                        })
                        .catch(function (err) {
                            var sysErrTitle = "KESALAHAN SISTEM / KONEKSI";
                            var sysErrMsg = "Terjadi kesalahan sistem saat melakukan proses approval untuk Request " + 
                                
                                
                                targetDocsStr + ".";
                            showToast("Approval error: " + err.message, "error");
                            showPageApprovalAlert(false, sysErrTitle, sysErrMsg, err.message);
                            showUploadResultNotification(false, "System Error", sysErrMsg, err.message);
                        })
                        .finally(function () {
                            setApproveLoadingState(false, targetReqNos);
                            cancelApproveConfirm();
                            isApprovingInProgress = false;
                            loadStagingList();
                        });
                }

                function setApproveLoadingState(isLoading, targetReqNos) {
                    var btnExecute = document.getElementById("btnExecuteApproveModal");
                    var btnCancel = document.getElementById("btnCancelApproveModal");
                    var textExecute = document.getElementById("btnExecuteApproveText");

                    if (isLoading) {
                        if (btnExecute) {
                            btnExecute.disabled = true;
                            btnExecute.classList.add("opacity-75", "cursor-not-allowed");
                        }
                        if (btnCancel) {
                            btnCancel.disabled = true;
                            btnCancel.classList.add("opacity-50", "cursor-not-allowed");
                        }
                        if (textExecute) {
                            textExecute.innerHTML = '<span class="inline-block animate-spin w-3.5 h-3.5' +
    ' border-2 borde' +
                                'r-white border-t-transparent rounded-full mr-1.5 align-middle"></' +
                                'span> Memproses SAP...';
                        }
                    } else {
                        if (btnExecute) {
                            btnExecute.disabled = false;
                            btnExecute.classList.remove("opacity-75", "cursor-not-allowed");
                        }
                        if (btnCancel) {
                            btnCancel.disabled = false;
                            btnCancel.classList.remove("opacity-50", "cursor-not-allowed");
                        }
                        if (textExecute) {
                            textExecute.innerText = 'Ya, Approve Sekarang';
                        }
                    }

                    var btnSel = "button[onclick*='quickApprove'], " +
                        "button[onclick*='triggerBulkApprove']";
                    var allApproveBtns = document.querySelectorAll(btnSel);
                    allApproveBtns.forEach(function (btn) {
                        btn.disabled = isLoading;
                        if (isLoading) {
                            btn.classList.add("opacity-50", "cursor-not-allowed");
                        } else {
                            btn.classList.remove("opacity-50", "cursor-not-allowed");
                        }
                    });

                    if (targetReqNos && targetReqNos.length === 1) {
                        var rowBtn = document.getElementById("btn_approve_" + targetReqNos[0]);
                        if (rowBtn) {
                            if (isLoading) {
                                rowBtn.setAttribute("data-orig-html", rowBtn.innerHTML);
                                rowBtn.innerHTML = '<span class="inline-block animate-spin w-3 h-3 border-2 border-wh' +
                                    'ite border-t-transparent rounded-full mr-1"></span> Processing...';
                            } else {
                                var orig = rowBtn.getAttribute("data-orig-html");
                                if (orig) rowBtn.innerHTML = orig;
                            }
                        }
                    }
                }

                function formatCleanMaterialMsg(text) {
                    if (!text || typeof text !== 'string') return text;
                    return text.replace(/(Nomor Material:\s*)0+([1-9A-Za-z]\w*)/gi, '$1$2')
                               .replace(/(\b)0+([1-9A-Za-z]\w{4,})/g, '$1$2');
                }

                function showPageApprovalAlert(isSuccess, title, message, details) {
                    var banner = document.getElementById("pageApprovalAlert");
                    var icon = document.getElementById("pageApprovalAlertIcon");
                    var titleEl = document.getElementById("pageApprovalAlertTitle");
                    var msgEl = document.getElementById("pageApprovalAlertMessage");
                    var detailEl = document.getElementById("pageApprovalAlertDetail");

                    if (!banner) return;

                    message = formatCleanMaterialMsg(message || "");
                    details = formatCleanMaterialMsg(details || "");

                    if (isSuccess) {
                        banner.className = "mb-6 rounded-2xl p-4 transition-all duration-300 shadow" +
                            "-sm border bg-emerald-50 border-emerald-200 text-emeral" +
                            "d-900";
                        icon.className = "w-9 h-9 rounded-xl flex items-center justify-center fon" +
                            "t-bold text-base shrink-0 mt-0.5 shadow-inner bg-emeral" +
                            "d-100 text-emerald-700 border border-emerald-300";
                        icon.innerHTML = "&#10003;";
                    } else {
                        banner.className = "mb-6 rounded-2xl p-4 transition-all duration-300 shadow" +
                            "-sm border bg-rose-50 border-rose-200 text-rose-900";
                        icon.className = "w-9 h-9 rounded-xl flex items-center justify-center fon" +
                            "t-bold text-base shrink-0 mt-0.5 shadow-inner bg-rose-1" +
                            "00 text-rose-700 border border-rose-300";
                        icon.innerHTML = "&#10005;";
                    }

                    if (titleEl) titleEl.innerText = title || 
                        (isSuccess ? "APPROVAL BERHASIL" : "APPROVAL GAGAL");
                    if (msgEl) msgEl.innerText = message || "";

                    if (detailEl) {
                        if (details && details.trim() !== "") {
                            detailEl.innerText = details;
                            detailEl.className = isSuccess ?
                                "mt-2.5 p-3 rounded-xl text-[11px] font-mono bg-white " +
                                 "border border-emerald-200 text-emerald-800 max-h-40 overflow-y-auto" :
                                "mt-2.5 p-3 rounded-xl text-[11px] font-mono bg-white " +
                                 "border border-rose-200 text-rose-800 max-h-40 overflow-y-auto";
                            detailEl.classList.remove("hidden");
                        } else {
                            detailEl.classList.add("hidden");
                        }
                    }

                    banner.classList.remove("hidden");
                    banner.scrollIntoView({ behavior: "smooth", block: "nearest" });
                }

                function closePageApprovalAlert() {
                    var banner = document.getElementById("pageApprovalAlert");
                    if (banner) banner.classList.add("hidden");
                }

                function openRejectModal(mode, reqNo) {
                    if (!reqNo) reqNo = '';
                    document.getElementById("modalMode").value = mode;
                    document.getElementById("modalTargetReqNo").value = reqNo;
                    document.getElementById("rejectReasonInput").value = '';
                    document.getElementById("rejectModal").classList.remove("hidden");
                }

                function closeRejectModal() {
                    document.getElementById("rejectModal").classList.add("hidden");
                }

                function submitRejection() {
                    var mode = document.getElementById("modalMode").value;
                    var singleReqNo = document.getElementById("modalTargetReqNo").value;
                    var reason = document.getElementById("rejectReasonInput").value.trim();

                    if (!reason) {
                        showToast("Rejection reason is required.", "error");
                        return;
                    }

                    var targetReqNos = (mode === 'SINGLE') ? singleReqNo : selectedReqNos.join(',');
                    if (!targetReqNos) {
                        showToast("No request selected.", "error");
                        return;
                    }

                    var formData = new FormData();
                    formData.append("REQ_NOS", targetReqNos);
                    formData.append("REJ_REASON", reason);

                    fetch("?action=BULK_REJECT", { method: "POST", body: formData })
                        .then(function (res) { return res.json(); })
                        .then(function (data) {
                            showToast("Request rejected.", "info");
                            closeRejectModal();
                            loadStagingList();
                        })
                        .catch(function () { showToast("Rejection failed.", "error"); });
                }

                function showUploadResultNotification(isSuccess, title, message, details) {
                    var modal = document.getElementById("uploadResultModal");
                    var header = document.getElementById("uploadResultHeader");
                    var icon = document.getElementById("uploadResultIcon");
                    var heading = document.getElementById("uploadResultHeading");
                    var msg = document.getElementById("uploadResultMessage");
                    var detailBox = document.getElementById("uploadResultDetailBox");

                    if (!modal) return;

                    message = formatCleanMaterialMsg(message || "");
                    details = formatCleanMaterialMsg(details || "");

                    if (isSuccess) {
                        header.className = "px-5 py-4 border-b border-emerald-200 bg-emerald-50 " +
                            "text-emerald-800 flex items-center justify-between";
                        icon.className = "w-14 h-14 rounded-full mx-auto flex items-center justify-center " +
                            "text-2xl font-bold bg-emerald-100 text-emerald-600 border-2 " +
                            "border-emerald-400 shadow-xs";
                        icon.innerHTML = "&#10003;";
                        heading.innerText = "BERHASIL DI-UPLOAD KE SAP S/4HANA!";
                        heading.className = "text-sm font-bold text-emerald-800 uppercase tracking-wide";
                    } else {
                        header.className = "px-5 py-4 border-b border-rose-200 bg-rose-50 " +
                            "text-rose-800 flex items-center justify-between";
                        icon.className = "w-14 h-14 rounded-full mx-auto flex items-center justify-center " +
                            "text-2xl font-bold bg-rose-100 text-rose-600 border-2 " +
                            "border-rose-400 shadow-xs";
                        icon.innerHTML = "&#10005;";
                        heading.innerText = "GAGAL UPLOAD KE SAP S/4HANA!";
                        heading.className = "text-sm font-bold text-rose-800 uppercase tracking-wide";
                    }

                    msg.innerText = message || "";
                    if (details && details.trim() !== "") {
                        detailBox.innerText = details;
                        detailBox.classList.remove("hidden");
                    } else {
                        detailBox.classList.add("hidden");
                    }

                    modal.classList.remove("hidden");
                }

                function closeUploadResultModal() {
                    var modal = document.getElementById("uploadResultModal");
                    if (modal) modal.classList.add("hidden");
                    loadStagingList();
                }

                function deleteDraft(reqNo) {
                    if (!confirm("Delete draft " + reqNo + "?")) return;
                    var formData = new FormData();
                    formData.append("REQ_NO", reqNo);

                    fetch("?action=DELETE_DRAFT", { method: "POST", body: formData })
                        .then(function (res) { return res.json(); })
                        .then(function (data) {
                            showToast("Draft " + reqNo + " deleted.", "info");
                            loadStagingList();
                        })
                        .catch(function () { showToast("Failed to delete draft.", "error"); });
                }

                function showToast(message, type) {
                    if (!type) type = "info";
                    var dotClasses = { success: "bg-emerald-500", error: "bg-rose-500", info: "bg-sky-500" };
                    var bgClasses = {
                        success: "bg-slate-900 border-l-4 border-emerald-500",
                        error: "bg-slate-900 border-l-4 border-rose-500",
                        info: "bg-slate-900 border-l-4 border-sky-500"
                    };
                    var stack = document.getElementById("toastStack");
                    if (!stack) return;
                    var toast = document.createElement("div");
                    toast.className = 'min-w-[280px] max-w-[380px] ' + (bgClasses[type] || bgClasses.info) + 
                        ' text-white p-3 rounded-xl text-xs flex items-start gap-2.5 ' +
                        'shadow-lg transition-all duration-300 opacity-100 translate-y-0';

                    var tStr = '';
                    tStr += '<span class="shrink-0 mt-1 w-1.5 h-1.5 rounded-full ' + 
                        (dotClasses[type] || dotClasses.info) + '"></span>';
                    tStr += '<span class="font-medium">' + escapeHtml(message) + '</span>';
                    toast.innerHTML = tStr;

                    stack.appendChild(toast);

                    setTimeout(function () {
                        toast.classList.add("opacity-0", "translate-y-2");
                        setTimeout(function () { toast.remove(); }, 300);
                    }, 3500);
                }

                function loadSidebarCounters() {
                    fetch("?OnInputProcessing=GET_COUNTERS&action=GET_COUNTERS", { method: "POST" })
                        .then(function (res) {
                            var ct = res.headers.get("content-type") || "";
                            if (ct.indexOf("application/json") !== -1) {
                                return res.json();
                            }
                            return res.text().then(function (text) {
                                try { return JSON.parse(text); } catch (e) { return null; }
                            });
                        })
                        .then(function (cnts) {
                            if (!cnts) return;
                            var pMat = document.getElementById("sbBadgeMatPending");
                            var pBp = document.getElementById("sbBadgeBpPending");
                            var p = document.getElementById("sbBadgePending");
                            var a = document.getElementById("sbBadgeApproved");
                            var r = document.getElementById("sbBadgeRejected");
                            if (pMat) {
                                if (cnts.mat_pending !== undefined) pMat.innerText = cnts.mat_pending;
                                else if (cnts.pending !== undefined) pMat.innerText = cnts.pending;
                            }
                            if (pBp && cnts.bp_pending !== undefined) pBp.innerText = cnts.bp_pending;
                            if (p && cnts.pending !== undefined) p.innerText = cnts.pending;
                            if (a && cnts.approved !== undefined) a.innerText = cnts.approved;
                            if (r && cnts.rejected !== undefined) r.innerText = cnts.rejected;
                        })
                        .catch(function (e) { console.error("Counter load err", e); });
                }

                
                var currentMmZoom = 1;
                var mmPanX = 0;
                var mmPanY = 0;
                var isMmDragging = false;
                var startMmDragX = 0;
                var startMmDragY = 0;

document.addEventListener("DOMContentLoaded", function () {
                    initMmImageZoomEvents();
                    loadSidebarCounters();
                });
