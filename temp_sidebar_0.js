
    (function() {
        var path = (window.location.pathname || "").toLowerCase();
        var matEl = document.getElementById("sbNavMaterial");
        var bpEl = document.getElementById("sbNavBp");
        var approvedEl = document.getElementById("sbNavApproved");
        var rejectedEl = document.getElementById("sbNavRejected");

        function setTabActive(el, activeClass, textBadgeClass) {
            if (!el) return;
            el.className = "group flex items-center justify-between px-3.5 py-2.5 rounded-xl font-bold text-xs transition-all duration-200 " + activeClass;
            var badge = el.querySelector("span[id^='sbBadge']");
            if (badge) {
                badge.className = "px-2 py-0.5 text-[10px] font-bold rounded-full " + textBadgeClass;
            }
        }

        // 1. Highlight active menu item based on current URL path
        if (path.indexOf("approve_bp") !== -1) {
            setTabActive(bpEl, "bg-sky-600 text-white shadow-md shadow-sky-600/30", "bg-white/20 text-white shadow-xs");
        } else if (path.indexOf("history_approved") !== -1) {
            setTabActive(approvedEl, "bg-emerald-600 text-white shadow-md shadow-emerald-600/30", "bg-white/20 text-white shadow-xs");
        } else if (path.indexOf("history_rejected") !== -1) {
            setTabActive(rejectedEl, "bg-rose-600 text-white shadow-md shadow-rose-600/30", "bg-white/20 text-white shadow-xs");
        } else {
            setTabActive(matEl, "bg-emerald-600 text-white shadow-md shadow-emerald-600/30", "bg-white/20 text-white shadow-xs");
        }

        // 2. Intelligent relative link adjustment for local file preview
        if (window.location.protocol === "file:") {
            var curr = (window.location.pathname || "").split(String.fromCharCode(92)).join("/").toLowerCase();
            var inMat = curr.indexOf("/approve_material/") !== -1;
            var inBp = curr.indexOf("/approve_bp/") !== -1;
            var inHistAppr = curr.indexOf("/hist_approved/") !== -1;
            var inHistRej = curr.indexOf("/reject/") !== -1;

            if (matEl) {
                if (inMat) matEl.setAttribute("href", "approve_material.htm");
                else if (inBp) matEl.setAttribute("href", "../approve_material/approve_material.htm");
                else if (inHistAppr || inHistRej) matEl.setAttribute("href", "../Approval/approve_material/approve_material.htm");
            }
            if (bpEl) {
                if (inBp) bpEl.setAttribute("href", "approve_bp.htm");
                else if (inMat) bpEl.setAttribute("href", "../approve_bp/approve_bp.htm");
                else if (inHistAppr || inHistRej) bpEl.setAttribute("href", "../Approval/approve_bp/approve_bp.htm");
            }
            if (approvedEl) {
                if (inHistAppr) approvedEl.setAttribute("href", "history_approved.htm");
                else if (inHistRej) approvedEl.setAttribute("href", "../HIST_APPROVED/history_approved.htm");
                else if (inMat || inBp) approvedEl.setAttribute("href", "../../HIST_APPROVED/history_approved.htm");
            }
            if (rejectedEl) {
                if (inHistRej) rejectedEl.setAttribute("href", "history_rejected.htm");
                else if (inHistAppr) rejectedEl.setAttribute("href", "../REJECT/history_rejected.htm");
                else if (inMat || inBp) rejectedEl.setAttribute("href", "../../REJECT/history_rejected.htm");
            }
            var brandLink = document.getElementById("sbBrandLink");
            if (brandLink) {
                if (inMat || inBp) brandLink.setAttribute("href", "../../landing/landing_page.htm");
                else if (inHistAppr || inHistRej) brandLink.setAttribute("href", "../landing/landing_page.htm");
            }
        }

        // 3. Dynamic Badge Counter Updater Function
        function updateBadgeElements(cnts) {
            if (!cnts) return;
            var pMat = document.getElementById("sbBadgeMatPending");
            var pBp = document.getElementById("sbBadgeBpPending");
            var a = document.getElementById("sbBadgeApproved");
            var r = document.getElementById("sbBadgeRejected");

            // Material Pending badge
            if (cnts.mat_pending !== undefined) {
                if (pMat) pMat.innerText = cnts.mat_pending;
            } else if (cnts.pending !== undefined && path.indexOf("approve_bp") === -1) {
                if (pMat) pMat.innerText = cnts.pending;
            }

            // BP Pending badge
            if (cnts.bp_pending !== undefined) {
                if (pBp) pBp.innerText = cnts.bp_pending;
            } else if (cnts.pending !== undefined && path.indexOf("approve_bp") !== -1) {
                if (pBp) pBp.innerText = cnts.pending;
            }

            // Approved & Rejected badge
            if (a && cnts.approved !== undefined) a.innerText = cnts.approved;
            if (r && cnts.rejected !== undefined) r.innerText = cnts.rejected;
        }

        // Expose globally so host pages can invoke it after approval / rejection
        window.loadSidebarCounters = function() {
            fetch("?OnInputProcessing=GET_COUNTERS&action=GET_COUNTERS", { method: "POST" })
            .then(function(res) {
                var ct = res.headers.get("content-type") || "";
                if (ct.indexOf("application/json") !== -1) {
                    return res.json();
                }
                return res.text().then(function(text) {
                    try { return JSON.parse(text); } catch(e) { return null; }
                });
            })
            .then(function(cnts) {
                updateBadgeElements(cnts);
            })
            .catch(function(e) {
                console.error("Sidebar counter fetch err:", e);
            });
        };

        // 4. Run immediately and attach reactive triggers
        window.loadSidebarCounters();

        // Refresh when window regains focus (approver switches tabs)
        window.addEventListener("focus", function() {
            if (typeof window.loadSidebarCounters === "function") {
                window.loadSidebarCounters();
            }
        });

        // Periodic light background refresh (every 30s)
        setInterval(function() {
            if (typeof window.loadSidebarCounters === "function") {
                window.loadSidebarCounters();
            }
        }, 30000);
    })();
